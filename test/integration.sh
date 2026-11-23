#!/bin/sh
set -eu

IMAGE=${1:-karako-backup:ci}
P=kbtest

cleanup() {
  docker rm -f "$P-pg" "$P-maria" "$P-skip" > /dev/null 2>&1 || true
  docker volume rm "$P-files" "$P-repo" > /dev/null 2>&1 || true
}
trap cleanup EXIT
cleanup

fail() { echo "FAIL: $*"; exit 1; }

docker volume create "$P-files" > /dev/null
docker run --rm -v "$P-files:/v" alpine:3.22 sh -c 'echo hello > /v/hello.txt'
docker run -d --name "$P-pg" -e POSTGRES_PASSWORD=ci -e POSTGRES_USER=app postgres:18-alpine > /dev/null
docker run -d --name "$P-maria" -e MARIADB_ROOT_PASSWORD=ci mariadb:11 > /dev/null
docker run -d --name "$P-skip" --label karako-backup.skip=true postgres:18-alpine sleep 600 > /dev/null

for _ in $(seq 1 60); do
  docker exec "$P-pg" pg_isready -U app > /dev/null 2>&1 \
    && docker exec "$P-maria" mariadb -uroot -pci -e 'SELECT 1' > /dev/null 2>&1 && break
  sleep 2
done
docker exec "$P-pg" psql -U app -d app -c "CREATE TABLE marker (v text); INSERT INTO marker VALUES ('pg-marker-42');" > /dev/null
docker exec "$P-maria" mariadb -uroot -pci -e "CREATE DATABASE shop; CREATE TABLE shop.marker (v text); INSERT INTO shop.marker VALUES ('maria-marker-42');"

run() {
  docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /var/lib/docker/volumes:/var/lib/docker/volumes:ro \
    -v "$P-repo:/repo" \
    -e BACKUP_HOST=ci -e RESTIC_REPOSITORY=/repo -e RESTIC_PASSWORD=ci \
    "$IMAGE" "$@"
}

run backup
listing=$(run restic ls latest)

echo "$listing" | grep -q "/dumps/$P-pg.sql.gz" || fail "postgres dump missing"
echo "$listing" | grep -q "/dumps/$P-maria.sql.gz" || fail "mariadb dump missing"
echo "$listing" | grep -q "/var/lib/docker/volumes/$P-files/_data/hello.txt" || fail "volume file missing"
echo "$listing" | grep -q "/dumps/$P-skip.sql.gz" && fail "skipped container was dumped"
echo "$listing" | grep -q "/var/lib/docker/volumes/$P-repo/" && fail "repository volume was backed up"

pg_volume=$(docker inspect -f '{{range .Mounts}}{{.Name}}{{end}}' "$P-pg")
echo "$listing" | grep -q "/var/lib/docker/volumes/$pg_volume/" && fail "raw postgres volume was backed up"

run sh -c "restic dump latest /dumps/$P-pg.sql.gz | gzip -dc" | grep -q pg-marker-42 || fail "postgres marker not restored"
run sh -c "restic dump latest /dumps/$P-maria.sql.gz | gzip -dc" | grep -q maria-marker-42 || fail "mariadb marker not restored"
[ "$(run restic dump latest "/var/lib/docker/volumes/$P-files/_data/hello.txt")" = hello ] || fail "volume file not restored"

run backup > /dev/null
run backup > /dev/null
[ "$(run restic snapshots --json | jq length)" = 2 ] || fail "retention kept more than the newest and the oldest snapshot of the day"

echo "integration suite passed"

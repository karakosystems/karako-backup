FROM restic/restic:0.20.0

LABEL org.opencontainers.image.title="karako-backup" \
      org.opencontainers.image.description="Daily encrypted backups of a Docker host with restic: logical dumps of every Postgres and MariaDB container, every Docker volume, retention, integrity checks and Discord alerts." \
      org.opencontainers.image.url="https://github.com/karakosystems/karako-backup" \
      org.opencontainers.image.source="https://github.com/karakosystems/karako-backup" \
      org.opencontainers.image.documentation="https://github.com/karakosystems/karako-backup#readme" \
      org.opencontainers.image.vendor="Karako Systems" \
      org.opencontainers.image.licenses="MIT"

RUN apk add --no-cache docker-cli jq curl tzdata

COPY --chmod=755 bin/ /usr/local/bin/

ENV TZ=UTC \
    BACKUP_STATE_DIR=/state \
    BACKUP_DUMPS_DIR=/dumps \
    BACKUP_VOLUMES_DIR=/var/lib/docker/volumes

VOLUME ["/state", "/dumps", "/root/.cache/restic"]

HEALTHCHECK --interval=5m --timeout=10s --start-period=25h --retries=3 \
    CMD ["sh", "-c", "find \"$BACKUP_STATE_DIR/last-success\" -mmin -1560 | grep -q ."]

ENTRYPOINT ["/usr/local/bin/entrypoint"]
CMD ["cron"]

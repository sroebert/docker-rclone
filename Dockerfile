# docker buildx build --platform linux/amd64,linux/arm64,linux/arm --push -t sroebert/rclone:latest .
FROM rclone/rclone:latest

# Setup
LABEL maintainer="sroebert"

ENV SYNC_SRC=
ENV SYNC_DEST=
ENV SYNC_OPTS=-v
ENV SYNC_OPTS_EVAL=
ENV SYNC_ONCE=
ENV RCLONE_CMD=sync
ENV RCLONE_DIR_CMD=ls
ENV RCLONE_DIR_CHECK_SKIP=
ENV RCLONE_OPTS="--config /config/rclone.conf"
ENV OUTPUT_LOG=
ENV ROTATE_LOG=
ENV CRON=
ENV CRON_ABORT=
ENV FORCE_SYNC=
ENV CHECK_URL=
ENV FAIL_URL=
ENV TZ=
ENV UID=
ENV GID=

COPY entrypoint.sh /
COPY sync.sh /
COPY sync-abort.sh /

VOLUME ["/config"]
VOLUME ["/logs"]

ENTRYPOINT ["/entrypoint.sh"]

CMD [""]

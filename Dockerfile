FROM docker.io/ubuntu:24.04

RUN apt-get update && apt-get install -y  \
    rsync  \
    openssh-client \
    inotify-tools

COPY --chmod=755 rsync.sh /opt/rsync.sh
ENV ALLOWED_RETURN_CODES="0,23"

ENTRYPOINT ["/opt/rsync.sh"]

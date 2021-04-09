
ARG BASE_CTR
ARG VERSION
FROM $BASE_CTR:$VERSION

COPY --chown=terrauser:terrauser lcd-entrypoint.sh .

RUN chmod +x lcd-entrypoint.sh

ENTRYPOINT ["/bin/sh", "./lcd-entrypoint.sh"]

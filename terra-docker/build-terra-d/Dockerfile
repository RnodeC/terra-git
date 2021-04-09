
ARG BASE_CTR
ARG VERSION
FROM $BASE_CTR:$VERSION

COPY --chown=terrauser:terrauser terrad-entrypoint.sh .

RUN chmod +x terrad-entrypoint.sh

ENTRYPOINT ["/bin/sh", "./terrad-entrypoint.sh"]

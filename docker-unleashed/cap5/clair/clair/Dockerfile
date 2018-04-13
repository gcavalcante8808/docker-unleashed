FROM quay.io/coreos/clair:v2.0.2
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY config.yaml.sample /config/config.yaml.sample
RUN apk add --no-cache bash && \
    chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]


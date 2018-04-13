FROM alpine:3.6 as downloader
ARG VERSION=2.0.2
RUN apk add --no-cache ca-certificates curl && \
    curl -L --output /klar https://github.com/optiopay/klar/releases/download/v${VERSION}/klar-${VERSION}-linux-amd64
    
FROM alpine:3.6
COPY --from=downloader /klar /usr/bin/klar
RUN chmod +x /usr/bin/klar
ENTRYPOINT ["/usr/bin/klar"]


FROM nginx:alpine

HEALTHCHECK --interval=30s \
            --timeout=5s \
            --start-period=10s \
            --retries=3 \
  CMD wget -q --spider http://127.0.0.1/ || exit 1

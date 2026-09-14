FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html
COPY health /usr/share/nginx/html/health

HEALTHCHECK --interval=5s --timeout=2s --start-period=3s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1/health || exit 1

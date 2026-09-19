FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html

HEALTHCHECK --interval=5s --timeout=2s --start-period=2s --retries=3 \
  CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1

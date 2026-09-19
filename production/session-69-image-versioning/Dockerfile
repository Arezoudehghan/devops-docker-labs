FROM nginx:1.28-alpine

ARG APP_VERSION=dev

COPY app/index.html /usr/share/nginx/html/index.html
COPY app/health.html /usr/share/nginx/html/health.html

RUN printf 'VERSION=%s\n' "$APP_VERSION" > /usr/share/nginx/html/version.txt

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1/health.html || exit 1

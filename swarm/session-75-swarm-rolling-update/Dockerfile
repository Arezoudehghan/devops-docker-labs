FROM python:3.12-alpine

ARG APP_VERSION=dev
ARG HEALTH_MODE=ok

ENV APP_VERSION=${APP_VERSION}
ENV HEALTH_MODE=${HEALTH_MODE}
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY app.py /app/app.py

EXPOSE 8000

HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=3 \
  CMD python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2).read()" || exit 1

CMD ["python3", "/app/app.py"]

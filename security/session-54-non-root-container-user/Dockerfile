FROM python:3.12-slim

RUN mkdir -p /app \
    && chown 10001:10001 /app

WORKDIR /app

COPY --chown=10001:10001 index.html /app/index.html

USER 10001:10001

EXPOSE 8000

CMD ["python", "-m", "http.server", "8000", "--bind", "0.0.0.0"]

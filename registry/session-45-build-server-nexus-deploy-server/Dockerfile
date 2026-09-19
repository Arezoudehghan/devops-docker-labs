FROM python:3.12-slim

WORKDIR /app

COPY index.html /app/index.html

EXPOSE 8000

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/', timeout=2)"

CMD ["python", "-m", "http.server", "8000", "--bind", "0.0.0.0"]

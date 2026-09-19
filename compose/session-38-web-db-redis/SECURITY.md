# Security Notes

- Never commit a real `.env` file or real credentials.
- Use `.env.example` only as a safe template.
- PostgreSQL and Redis do not publish host ports in this lab.
- The Dockerfile uses `--trusted-host` only for the lab environment where TLS inspection may interfere with pip. In production, trust the correct organizational CA instead.
- This repository is an educational lab and is not a production deployment template.

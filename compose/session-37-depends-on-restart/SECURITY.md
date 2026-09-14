# Security Notes

- Do not commit the real `.env` file.
- Replace the example PostgreSQL password before running the lab.
- PostgreSQL port `5432` is intentionally not published on the Docker host.
- Adminer is a lab administration tool and must not be exposed to the public internet.
- If UFW is active on `DEV-2`, allow TCP `8086` only from the real client VM address. The address `192.0.2.10` in the documentation is an example.
- Back up `db_data` before any destructive volume operation.

The following command permanently deletes the PostgreSQL volume:

```bash
docker compose down -v
```


## Reporting a vulnerability

Follow the repository-wide [security policy](../SECURITY.md). Do not disclose security-sensitive details in a public issue.

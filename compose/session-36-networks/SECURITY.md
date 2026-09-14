# Security Policy

## Scope

This repository is an educational Docker Compose networking lab. Do not treat the included configuration as a complete production security baseline.

## Safe usage

- Do not commit `.env` files containing credentials.
- Do not publish Redis port `6379` unless a documented requirement exists.
- Keep Redis attached only to the internal backend network.
- Review Docker image updates before deployment.
- Restrict host firewall access to the published application port.
- Back up named volumes before destructive cleanup.

## Destructive command warning

The following command deletes the Redis named volume and its stored data:

```bash
docker compose down -v
```

Use it only when data removal is intentional.

## Reporting a security issue

Follow the repository-wide [security policy](../SECURITY.md). Do not disclose security-sensitive details in a public issue.

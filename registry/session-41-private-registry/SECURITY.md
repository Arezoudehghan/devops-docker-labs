# Security Notes — Session 41 Private Registry

This lab intentionally demonstrates an HTTP-only private Docker Registry.

## Lab-only assumptions

- No TLS is configured.
- No Registry authentication is configured.
- No authorization policy is configured.
- Docker is configured with an `insecure-registries` entry.

Do not expose this Registry to the public Internet.

## Production direction

A production Registry should use TLS, authentication, authorization, controlled network access, backup, monitoring, and an organization-approved artifact retention policy.

When this course moves to Nexus Repository, use Docker hosted repositories with appropriate access controls and TLS instead of the unsecured test configuration used here.

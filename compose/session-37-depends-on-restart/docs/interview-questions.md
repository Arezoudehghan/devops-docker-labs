# Docker Compose Dependency and Restart Interview Questions

## 1. What does short-form `depends_on` guarantee?

It guarantees dependency startup order, but it does not wait for the application inside the dependency container to become healthy.

## 2. How do you wait for a database to become ready?

Define a meaningful database health check and use long-form `depends_on` with `condition: service_healthy`.

## 3. What is the difference between `service_started` and `service_healthy`?

`service_started` requires the dependency container to be running. `service_healthy` requires its configured health check to pass.

## 4. What is `service_completed_successfully` used for?

It is used for one-time dependencies such as schema migrations or initialization jobs that must exit successfully before another service starts.

## 5. What does service-level `restart: unless-stopped` do?

Docker Engine restarts the container after an unexpected exit and after daemon or host restart, unless an operator intentionally stopped it.

## 6. What does `depends_on.restart: true` do?

Compose restarts the dependent service when the dependency is explicitly restarted or updated by a Compose operation.

## 7. Does `depends_on.restart` apply after `docker kill`?

No. A runtime restart performed by Docker Engine does not trigger the Compose dependency restart behavior.

## 8. Does an unhealthy status automatically restart a container?

No. A health-check failure changes the health status but does not itself stop the container. Standard restart policies react to container exit.

## 9. Why is PostgreSQL port 5432 not published in this lab?

Only Adminer needs database access, and both services share the private `backend` network. Avoiding unnecessary host publication reduces exposure.

## 10. Why must Adminer use `db` instead of `localhost`?

Inside Adminer, `localhost` identifies the Adminer container itself. Docker DNS resolves the Compose service name `db` to the PostgreSQL container.

## 11. Is `depends_on` a replacement for application retry logic?

No. It coordinates startup. Applications still need retry and reconnect logic for dependency failures that occur after startup.

## 12. Why might changing `POSTGRES_PASSWORD` not change the active password?

The official image uses initialization variables only for an empty data directory. Existing named-volume data preserves the previously configured database credentials.

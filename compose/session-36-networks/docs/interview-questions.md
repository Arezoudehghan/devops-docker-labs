# Docker Compose Networking Interview Questions

## 1. What happens when no network is defined in a Compose file?

Compose creates a project-scoped default bridge network and attaches every service to it.

## 2. How do containers discover each other in Compose?

Docker provides embedded DNS. A container can resolve another service by its Compose service name when both services share a network.

## 3. Why should an application use `redis:6379` instead of a container IP?

Container IP addresses can change after recreation. The service name remains stable and is resolved by Docker DNS.

## 4. Why is `localhost:6379` incorrect inside the API container?

Inside a container, `localhost` points to that same container. Redis runs in another container and must be reached through the `redis` service name.

## 5. What is the difference between `ports` and `expose`?

`ports` publishes a container port on the Docker host. `expose` documents an internal port but does not publish it on the host.

## 6. Is `expose` a firewall rule?

No. Containers sharing a network can connect to listening ports even when those ports are not declared with `expose`.

## 7. Why is the API attached to two networks?

It must communicate with Frontend on `frontend_net` and Redis on `backend_net`. It acts as the controlled application-layer bridge between the two tiers.

## 8. Why can Frontend not resolve Redis?

They do not share a Docker network. Docker DNS exposes service names only to containers on a common network.

## 9. What does `internal: true` do?

It creates an externally isolated network. Containers attached only to that network do not receive normal external connectivity through it.

## 10. Can a Compose bridge network span DEV-1 and DEV-2?

No. A bridge network is local to one Docker host. Multi-host networking requires a technology such as Swarm overlay networking or Kubernetes networking.

## 11. Does `depends_on` provide permanent runtime recovery?

No. Health-based `depends_on` helps with startup order. It does not provide full orchestration or automatically restart every dependent service when an upstream service later becomes unhealthy.

## 12. What is an external Compose network?

It is a pre-existing Docker network managed outside the current Compose project. Compose attaches services to it but does not create or normally delete it.

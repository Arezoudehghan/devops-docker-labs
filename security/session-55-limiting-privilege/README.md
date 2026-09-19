# Session 55 — Limiting Container Privileges

Chapter 9 — Docker Security

This lab demonstrates the principle of least privilege in Docker containers. It compares normal containers with privileged containers, uses Linux capabilities with `--cap-add` and `--cap-drop`, and enables `no-new-privileges`.

## Execution host

Run the lab on `DEV-1`.

## 1. Root is not the same as privileged

Check the default user inside a temporary Ubuntu container:

```bash
docker run --rm ubuntu:24.04 id
```

Run the same command with privileged mode:

```bash
docker run --rm --privileged ubuntu:24.04 id
```

Both commands normally show UID 0 inside the container, but the privileged container receives much broader access.

## 2. Prepare the lab directory

```bash
mkdir -p /opt/docker-labs/session55
cd /opt/docker-labs/session55
```

Pull and verify the image:

```bash
docker pull ubuntu:24.04
docker images ubuntu:24.04
```

## Technical correction — `ip` command in Ubuntu 24.04

The minimal `ubuntu:24.04` image may not include the `ip` command. If a network-capability test returns `ip: not found`, install `iproute2` inside the temporary container before running that specific test, or use another lab image that already contains the `ip` utility.

This correction does not change the security concept being tested: creating a network interface requires the `NET_ADMIN` capability.

## 3. Compare normal and privileged network access

A normal container should not have `NET_ADMIN` by default:

```bash
docker run --rm \
  ubuntu:24.04 \
  ip link add dummy0 type dummy
```

A privileged container has broad access:

```bash
docker run --rm \
  --privileged \
  ubuntu:24.04 \
  sh -c 'ip link add dummy0 type dummy && ip link show dummy0'
```

## 4. Add only the required capability

Instead of using `--privileged`, add only `NET_ADMIN`:

```bash
docker run --rm \
  --cap-add=NET_ADMIN \
  ubuntu:24.04 \
  sh -c 'ip link add dummy0 type dummy && ip link show dummy0'
```

This is the preferred least-privilege approach when the application only needs network-administration operations.

## 5. Remove capabilities

Remove the `CHOWN` capability and test an ownership change:

```bash
docker run --rm \
  --cap-drop=CHOWN \
  ubuntu:24.04 \
  sh -c 'touch /tmp/test && chown 1000:1000 /tmp/test'
```

Drop every capability:

```bash
docker run --rm \
  --cap-drop=ALL \
  ubuntu:24.04 \
  sh -c 'touch /tmp/test && chown 1000:1000 /tmp/test'
```

Then add back only `CHOWN`:

```bash
docker run --rm \
  --cap-drop=ALL \
  --cap-add=CHOWN \
  ubuntu:24.04 \
  sh -c 'touch /tmp/test && chown 1000:1000 /tmp/test && ls -ln /tmp/test'
```

## 6. Enable no-new-privileges

Check the default value:

```bash
docker run --rm \
  ubuntu:24.04 \
  sh -c 'grep NoNewPrivs /proc/1/status'
```

Enable the protection:

```bash
docker run --rm \
  --security-opt no-new-privileges=true \
  ubuntu:24.04 \
  sh -c 'grep NoNewPrivs /proc/1/status'
```

The protected container should show `NoNewPrivs: 1`.

## 7. Run a hardened container

```bash
docker run -d \
  --name session55-secure \
  --cap-drop=ALL \
  --cap-add=CHOWN \
  --security-opt no-new-privileges=true \
  ubuntu:24.04 \
  sleep infinity
```

Verify privileged mode:

```bash
docker inspect session55-secure \
  --format 'Privileged={{.HostConfig.Privileged}}'
```

Verify added capabilities:

```bash
docker inspect session55-secure \
  --format 'CapAdd={{json .HostConfig.CapAdd}}'
```

Verify dropped capabilities:

```bash
docker inspect session55-secure \
  --format 'CapDrop={{json .HostConfig.CapDrop}}'
```

Verify Docker security options:

```bash
docker inspect session55-secure \
  --format 'SecurityOpt={{json .HostConfig.SecurityOpt}}'
```

Check the kernel flag from inside the container:

```bash
docker exec session55-secure \
  sh -c 'grep NoNewPrivs /proc/1/status'
```

## 8. Docker Compose hardening

The included `compose.yaml` applies the same policy:

- drop all capabilities,
- add only `CHOWN`,
- enable `no-new-privileges`,
- do not use privileged mode.

Validate the Compose file:

```bash
docker compose config
```

Start the service:

```bash
docker compose up -d
```

Check status:

```bash
docker compose ps
```

Verify the security settings:

```bash
docker inspect session55-compose-secure \
  --format 'Privileged={{.HostConfig.Privileged}}'
```

```bash
docker inspect session55-compose-secure \
  --format 'CapDrop={{json .HostConfig.CapDrop}}'
```

```bash
docker inspect session55-compose-secure \
  --format 'CapAdd={{json .HostConfig.CapAdd}}'
```

```bash
docker inspect session55-compose-secure \
  --format 'SecurityOpt={{json .HostConfig.SecurityOpt}}'
```

Verify `NoNewPrivs`:

```bash
docker exec session55-compose-secure \
  sh -c 'grep NoNewPrivs /proc/1/status'
```

Test the allowed `CHOWN` capability:

```bash
docker exec session55-compose-secure \
  sh -c 'touch /tmp/test && chown 1000:1000 /tmp/test && ls -ln /tmp/test'
```

A `NET_ADMIN` operation should fail because that capability was not added:

```bash
docker exec session55-compose-secure \
  ip link add dummy55 type dummy
```

## Cleanup

```bash
docker compose down
```

```bash
docker rm -f session55-secure 2>/dev/null || true
```

## Key security points

- Root inside a container is not the same as a privileged container.
- Avoid `--privileged` unless there is a specific and justified requirement.
- Prefer `--cap-drop=ALL` and add back only the capabilities the application actually needs.
- Treat broad capabilities such as `SYS_ADMIN` as high-risk permissions.
- Use `--security-opt no-new-privileges=true` to prevent processes from gaining new privileges.
- Test applications after capability reduction because some workloads require specific capabilities.

## Commands cheat sheet

See:

`docs/DevOps_Limiting_Privilege_Session_55_Commands_CheatSheet.txt`

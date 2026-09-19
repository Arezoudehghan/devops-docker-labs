# Session 53 — Why a Container Is Not Safer Than a VM

Chapter 9 — Docker Security

This lab demonstrates the security-boundary difference between Linux containers and virtual machines. It focuses on the shared host kernel, PID namespaces, container root, Docker security options, Docker socket access, bind mounts, and resource limits.

## Execution host

Run the lab on `DEV-1`.

## 1. Compare the host and container kernel

On the host:

```bash
uname -r
```

Inside a temporary container:

```bash
docker run --rm python:3.12-slim uname -r
```

Both commands should report the same host kernel release because the container does not boot its own kernel.

## 2. Check the container user space

```bash
docker run --rm ubuntu cat /etc/os-release
```

The container can have Ubuntu user-space files while still using the host kernel.

## 3. Create the PID namespace demo container

```bash
docker run -d \
  --name sec53-demo \
  python:3.12-slim \
  sleep infinity
```

Check PID 1 inside the container:

```bash
docker exec sec53-demo \
  sh -c 'cat /proc/1/status | head'
```

Get the host PID of the container's main process:

```bash
docker inspect \
  --format '{{.State.Pid}}' \
  sec53-demo
```

Store that PID and inspect it from the host:

```bash
PID=$(docker inspect \
  --format '{{.State.Pid}}' \
  sec53-demo)

ps -fp "$PID"
```

The process is PID 1 inside its PID namespace but has a normal host PID outside the container.

## 4. Check the user inside the container

```bash
docker exec sec53-demo id
```

This demonstrates that a process can run as root inside the container while Docker still applies other isolation controls.

## 5. Inspect Docker security options

```bash
docker info \
  --format '{{json .SecurityOptions}}'
```

Depending on the host configuration, the result can include controls such as seccomp, AppArmor, cgroup namespaces, rootless mode, or user namespaces.

## 6. Inspect Docker socket access

```bash
ls -l /var/run/docker.sock
```

Check whether the GitLab Runner user belongs to the Docker group:

```bash
id gitlab-runner
```

```bash
getent group docker
```

Membership in the Docker group is a high-privilege configuration because it allows access to the Docker daemon.

## 7. Safe read-only host bind-mount demo

This lab mounts the host root filesystem read-only so the container cannot modify it through this mount.

```bash
docker run --rm \
  --mount type=bind,src=/,dst=/host,readonly \
  python:3.12-slim \
  sh -c 'ls -ld /host /host/etc /host/var'
```

This demonstrates how container isolation can be weakened when host paths are deliberately exposed to a container.

## 8. Apply CPU and memory limits

```bash
docker run -d \
  --name sec53-limit \
  --memory=128m \
  --cpus=0.5 \
  python:3.12-slim \
  sleep infinity
```

Verify the configured limits:

```bash
docker inspect \
  --format 'Memory={{.HostConfig.Memory}} NanoCPUs={{.HostConfig.NanoCpus}}' \
  sec53-limit
```

## Cleanup

```bash
docker rm -f \
  sec53-demo \
  sec53-limit
```

Verify that no Session 53 lab containers remain:

```bash
docker ps -a \
  --filter name=sec53
```

## Key security points

- Linux containers normally share the host kernel.
- Container isolation is OS-level isolation rather than a separate guest-kernel boundary.
- Docker uses mechanisms such as namespaces, cgroups, capabilities, and seccomp.
- Root inside a container is not automatically equivalent to unrestricted host root, but it still requires careful hardening.
- Access to `/var/run/docker.sock` or the Docker group should be treated as high privilege.
- Avoid unnecessary privileged containers, writable host mounts, excessive capabilities, and unrestricted resource usage.

## Commands cheat sheet

See:

`docs/DevOps_Docker_Container_vs_VM_Security_Session_53_Commands_CheatSheet.txt`

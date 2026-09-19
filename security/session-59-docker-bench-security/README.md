# Session 59 — Docker Bench for Security

Chapter 9 — Docker Security

This lab demonstrates how to audit a Docker host and running containers with Docker Bench for Security, review WARN findings, compare a deliberately weak container with a hardened container, and keep before/after audit evidence.

## Execution host

Run the lab on DEV-1.

## Repository files

- `audit.sh`: runs Docker Bench and saves a baseline or post-hardening report.
- `weak-container.sh`: starts the intentionally weak `bench-demo` nginx container used for comparison.
- `hardened-container.sh`: starts the hardened `bench-demo` container with resource and runtime security controls.
- `cleanup.sh`: removes the demo container.
- `docs/DevOps_Docker_Bench_Security_Session_59_Commands_CheatSheet.txt`: command cheat sheet for this lesson.

## 1. Prepare Docker Bench

Docker Bench itself is not vendored into this repository. Clone the official project into the lab path:

~~~bash
mkdir -p /opt/docker-labs/session59
cd /opt/docker-labs/session59
git clone https://github.com/docker/docker-bench-security.git
cd docker-bench-security
~~~

Run the full audit:

~~~bash
sh docker-bench-security.sh -b -p
~~~

Review WARN findings:

~~~bash
grep '\[WARN\]' log/docker-bench-security.log
grep -c '\[WARN\]' log/docker-bench-security.log
~~~

## 2. Run the intentionally weak container

~~~bash
bash weak-container.sh
~~~

The weak example intentionally has no explicit memory limit, CPU limit, PID limit, read-only root filesystem, or loopback-only port binding.

Inspect its configuration:

~~~bash
docker inspect bench-demo --format '{{.HostConfig.Memory}}'
docker inspect bench-demo --format '{{.HostConfig.NanoCpus}}'
docker inspect bench-demo --format '{{.HostConfig.ReadonlyRootfs}}'
docker port bench-demo
~~~

Run the Docker Bench container-runtime checks from the cloned Docker Bench directory:

~~~bash
sh docker-bench-security.sh \
  -b \
  -c container_runtime \
  -i bench-demo \
  -p
~~~

## 3. Replace it with the hardened container

~~~bash
bash hardened-container.sh
~~~

The hardened example uses:

- `--memory=128m`
- `--cpus=0.50`
- `--pids-limit=100`
- `--read-only`
- writable `tmpfs` mounts only where nginx needs them
- `no-new-privileges:true`
- loopback-only port publishing on `127.0.0.1:18059`

Verify the service:

~~~bash
docker ps --filter name=bench-demo
curl -I http://127.0.0.1:18059
docker logs bench-demo
ss -lntp | grep 18059
~~~

Then rerun the same Docker Bench runtime checks and compare the findings.

## 4. Save before/after audit evidence

From the Docker Bench directory:

~~~bash
bash security/session-59-docker-bench-security/audit.sh baseline
~~~

After hardening:

~~~bash
bash security/session-59-docker-bench-security/audit.sh after-hardening
~~~

Compare the reports:

~~~bash
diff \
  /opt/docker-labs/session59/baseline.txt \
  /opt/docker-labs/session59/after-hardening.txt
~~~

## Security lessons demonstrated

- Docker Bench audits host, daemon, image, and runtime configuration; it is not an image vulnerability scanner.
- A WARN finding requires context and risk assessment before remediation.
- Resource limits are part of security because they reduce resource-abuse and denial-of-service risk.
- A read-only root filesystem should be combined with explicitly writable volumes or tmpfs paths where required.
- Avoid privileged containers unless there is a justified requirement.
- Bind services only to the interfaces that actually need exposure.
- Keep before/after audit evidence when performing hardening work.

## Cleanup

~~~bash
bash cleanup.sh
~~~

## Commands cheat sheet

See:

`docs/DevOps_Docker_Bench_Security_Session_59_Commands_CheatSheet.txt`

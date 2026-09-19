# Session 75 — Docker Swarm Rolling Update Cheat Sheet

A command-focused reference for **Session 75 only**.  
The commands below are taken from this rolling-update lab and grouped by purpose.

## 1. Environment and Swarm status checks

```bash
hostname
```

Displays the current host name.

```bash
ip -br addr
```

Displays network interfaces and IP addresses in compact form.

```bash
docker version
```

Shows Docker client and server version information.

```bash
docker info --format 'Swarm={{.Swarm.LocalNodeState}} ControlAvailable={{.Swarm.ControlAvailable}}'
```

Shows Swarm state and whether the node has manager control-plane capability.

## 2. Initialize Swarm when required

```bash
docker swarm init --advertise-addr 192.168.94.90
```

Initializes the Swarm manager on DEV-1 and advertises the manager address.

```bash
docker swarm join-token worker
```

Displays the worker join command and token. Run this on the manager.

```bash
docker node ls
```

Lists Swarm nodes and their current status. Run from a manager.

## 3. Registry access

```bash
docker login 192.168.94.90:8085
```

Authenticates to the Nexus Docker registry used by this lab.

```bash
curl -i http://192.168.94.90:8085/v2/
```

Checks whether the Docker Registry API endpoint is reachable.

## 4. Project directory

```bash
mkdir -p /opt/swarm-rolling-demo
```

Creates the project directory.

```bash
cd /opt/swarm-rolling-demo
```

Moves into the project directory.

## 5. Build the healthy v1 image

```bash
docker build \
  --build-arg APP_VERSION=v1 \
  --build-arg HEALTH_MODE=ok \
  -t 192.168.94.90:8085/swarm-rolling-demo:v1 .
```

Builds the initial healthy application image.

```bash
docker image inspect 192.168.94.90:8085/swarm-rolling-demo:v1
```

Inspects the local v1 image metadata.

```bash
docker push 192.168.94.90:8085/swarm-rolling-demo:v1
```

Pushes the v1 image to Nexus.

## 6. Build the healthy v2 image

```bash
docker build \
  --build-arg APP_VERSION=v2 \
  --build-arg HEALTH_MODE=ok \
  -t 192.168.94.90:8085/swarm-rolling-demo:v2 .
```

Builds the healthy v2 image used for the rolling update.

```bash
docker push 192.168.94.90:8085/swarm-rolling-demo:v2
```

Pushes v2 to Nexus.

## 7. Build the intentionally unhealthy image

```bash
docker build \
  --build-arg APP_VERSION=v3-broken \
  --build-arg HEALTH_MODE=fail \
  -t 192.168.94.90:8085/swarm-rolling-demo:v3-broken .
```

Builds the intentionally unhealthy image used to test automatic rollback.

```bash
docker push 192.168.94.90:8085/swarm-rolling-demo:v3-broken
```

Pushes the broken test image to Nexus.

## 8. Validate the Swarm stack

```bash
docker stack config -c stack.yml
```

Parses and renders the stack configuration before deployment.

## 9. Deploy the stack

```bash
docker stack deploy \
  --with-registry-auth \
  -c stack.yml \
  rolling
```

Deploys or updates the `rolling` stack and forwards registry authentication to Swarm nodes.

## 10. Verify the deployed service

```bash
docker stack services rolling
```

Shows services and replica state in the `rolling` stack.

```bash
docker service ls
```

Lists Swarm services on the cluster.

```bash
docker service ps rolling_web
```

Shows task history and placement for the `rolling_web` service.

```bash
docker service inspect --pretty rolling_web
```

Displays a readable service specification including update and rollback configuration.

## 11. Test the application

```bash
curl http://192.168.94.90:8088/
```

Tests the published application port through DEV-1.

```bash
for i in $(seq 1 10); do
  curl -s http://192.168.94.90:8088/
  sleep 1
done
```

Sends repeated requests so different replicas and versions can be observed.

```bash
curl http://192.168.94.91:8088/
```

Tests the Swarm routing mesh through DEV-2.

## 12. Change stack image from v1 to v2

```bash
sed -i \
  's/swarm-rolling-demo:v1/swarm-rolling-demo:v2/' \
  stack.yml
```

Updates the declared image tag in the stack file.

```bash
grep 'image:' stack.yml
```

Verifies the image line after editing.

## 13. Observe the rolling update

```bash
watch -n 1 'docker service ps rolling_web'
```

Refreshes the Swarm task list every second so the rollout can be observed.

```bash
while true; do
  curl -s http://192.168.94.90:8088/
  sleep 1
done
```

Continuously calls the application while old and new tasks coexist.

## 14. Verify the final image

```bash
docker service ps rolling_web
```

Checks that the updated tasks are running.

```bash
docker service inspect \
  --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' \
  rolling_web
```

Displays the image reference currently declared in the service specification.

```bash
for i in $(seq 1 10); do
  curl -s http://192.168.94.90:8088/
done
```

Sends repeated requests to confirm all responses are coming from the updated version.

## 15. Change stack image from v2 to the broken version

```bash
sed -i \
  's/swarm-rolling-demo:v2/swarm-rolling-demo:v3-broken/' \
  stack.yml
```

Changes the stack file to the intentionally unhealthy image.

```bash
grep 'image:' stack.yml
```

Verifies the broken image tag before deployment.

## 16. Inspect automatic rollback

```bash
docker service inspect --pretty rolling_web
```

Shows update and rollback status for the service.

```bash
docker service ps rolling_web --no-trunc
```

Shows full task errors and complete task IDs during a failed rollout.

```bash
curl http://192.168.94.90:8088/
```

Confirms that the service has returned to the previous healthy version after rollback.

## 17. Restore the stack file to v2

```bash
sed -i \
  's/swarm-rolling-demo:v3-broken/swarm-rolling-demo:v2/' \
  stack.yml
```

Restores the desired configuration in `stack.yml` after the rollback test.

```bash
grep 'image:' stack.yml
```

Confirms the stack file again references v2.

## 18. Manual rollback

```bash
docker service update --rollback rolling_web
```

Rolls the service back to its previous specification manually.

## 19. Rolling restart without changing the image

```bash
docker service update \
  --force \
  --update-parallelism 1 \
  --update-delay 10s \
  rolling_web
```

Forces task recreation as a controlled rolling restart.

## 20. Troubleshooting commands

```bash
docker service ps rolling_web --no-trunc
```

Shows complete task errors and task history.

```bash
docker service inspect --pretty rolling_web
```

Displays the current service configuration in a readable format.

```bash
docker ps -a
```

Lists running and stopped containers on the current node.

```bash
docker service logs rolling_web
```

Shows service logs.

```bash
docker service logs -f rolling_web
```

Follows service logs in real time.

```bash
docker pull 192.168.94.90:8085/swarm-rolling-demo:v2
```

Tests whether the healthy v2 image can be pulled manually from Nexus.

```bash
docker login 192.168.94.90:8085
```

Re-authenticates to the registry when image pulls fail.

```bash
docker node ls
```

Checks Swarm node availability and state.

```bash
systemctl status docker
```

Shows Docker daemon status on the current VM.

```bash
journalctl -u docker -n 100 --no-pager
```

Shows the most recent Docker daemon logs without opening a pager.

```bash
docker ps
```

Lists currently running containers.

```bash
docker inspect \
  --format '{{json .State.Health}}' \
  CONTAINER_ID
```

Displays the health-check state for a specific container.

## 21. Quick command set for troubleshooting this lab

```bash
docker node ls
docker service ls
docker service ps rolling_web --no-trunc
docker service inspect --pretty rolling_web
docker stack services rolling
```

Use this set first when the rolling-update lab does not behave as expected.

## Quick interview reminders

- `update_config.parallelism` controls how many tasks are updated at the same time.
- `update_config.delay` controls the pause between update batches.
- `order: start-first` starts the replacement task before stopping the old task.
- `order: stop-first` stops the old task before starting the replacement task.
- `failure_action: rollback` tells Swarm to return to the previous service specification after an update failure.
- `docker service update --rollback` performs a manual rollback.
- `docker service update --force` can be used for a rolling restart without changing the image.
- During a rolling update, old and new application versions may run at the same time.
- Application and database changes should therefore remain backward compatible during the rollout window.

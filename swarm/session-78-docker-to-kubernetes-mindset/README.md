# Session 78 — Docker to Kubernetes Mindset

This lab is the transition point from Docker and Docker Swarm concepts to Kubernetes. It uses a two-node K3s cluster to demonstrate desired state, Pods, Deployments, ReplicaSets, Services, probes, self-healing, scaling, rolling updates, and rollback.

## Learning goals

By the end of this lab you should be able to explain and demonstrate:

- The mental shift from directly managing containers to declaring desired state.
- The relationship: Deployment → ReplicaSet → Pod → Container.
- Why Pods are ephemeral and why Services provide stable access.
- The role of readiness and liveness probes.
- Self-healing after a Pod is deleted.
- Horizontal scaling by changing replica count.
- Rolling updates and rollback with a Deployment.
- Basic Kubernetes troubleshooting with kubectl.

## Lab environment

| Host | Address | Kubernetes role |
|---|---|---|
| `DEV-1` | `192.168.94.90` | K3s server / control plane / worker |
| `DEV-2` | `192.168.94.91` | K3s agent / worker |

K3s version used in this lesson:

```text
v1.36.4+k3s1
```

Application NodePort:

```text
30080
```

## Repository layout

```text
session-78-docker-to-kubernetes-mindset/
├── README.md
├── CHEATSHEET.md
└── k8s/
    └── web-demo.yaml
```

## 1. Pre-check both nodes

Run on both VMs:

```bash
hostname
hostname -I
ip -br addr
free -h
df -h /
nproc
docker ps
ss -lntup | grep -E '(:6443|:10250|:30080)\b' || true
ip route | grep -E '10\.42\.|10\.43\.' || true
```

The two nodes must have unique hostnames.

The default K3s networks used in this lab are:

- Pod CIDR: `10.42.0.0/16`
- Service CIDR: `10.43.0.0/16`

Do not continue if those ranges already conflict with an existing route in the lab.

## 2. Configure the lab proxy

Run on both nodes:

```bash
export HTTP_PROXY="http://192.168.95.204:2081"
export HTTPS_PROXY="http://192.168.95.204:2081"
export NO_PROXY="127.0.0.1,localhost,192.168.0.0/16,10.42.0.0/16,10.43.0.0/16"
```

## 3. Install K3s server on DEV-1

Run only on `DEV-1`:

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='v1.36.4+k3s1' sh -s - server \
  --node-ip 192.168.94.90 \
  --disable traefik \
  --disable servicelb \
  --disable metrics-server
```

Verify:

```bash
systemctl status k3s --no-pager
kubectl get nodes -o wide
kubectl get pods -A
```

## 4. Read the node token

Run on `DEV-1`:

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

Do not commit the real token to Git.

## 5. Join DEV-2

Run on `DEV-2` and replace the placeholder with the real token:

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='v1.36.4+k3s1' \
  K3S_URL='https://192.168.94.90:6443' \
  K3S_TOKEN='TOKEN_FROM_DEV_1' \
  sh -s - agent \
  --node-ip 192.168.94.91
```

Verify from `DEV-1`:

```bash
kubectl get nodes -o wide
kubectl cluster-info
kubectl get pods -A -o wide
```

Both nodes should become `Ready`.

## 6. Deploy the application

From the repository root on `DEV-1`:

```bash
kubectl apply --dry-run=client -f swarm/session-78-docker-to-kubernetes-mindset/k8s/web-demo.yaml
kubectl apply -f swarm/session-78-docker-to-kubernetes-mindset/k8s/web-demo.yaml
```

Verify the object chain:

```bash
kubectl get namespace devops-lab
kubectl -n devops-lab get deployment
kubectl -n devops-lab get rs
kubectl -n devops-lab get pods -o wide
kubectl -n devops-lab get service
```

The main relationship demonstrated by the lab is:

```text
Deployment
  ↓
ReplicaSet
  ↓
Pods
  ↓
Containers
```

Traffic flows through:

```text
Client
  ↓
NodePort 30080
  ↓
Service
  ↓
EndpointSlice
  ↓
Pod
  ↓
nginx :80
```

## 7. Test the Service

From `DEV-1`:

```bash
curl http://192.168.94.90:30080/
```

From `DEV-2`:

```bash
curl http://192.168.94.91:30080/
```

Run repeated requests:

```bash
for i in $(seq 1 10); do curl -s http://192.168.94.90:30080/; done
```

Expected response format:

```text
VERSION=v1 POD=web-demo-xxxxxxxxxx-xxxxx
```

## 8. Self-healing test

Select one Pod:

```bash
POD=$(kubectl -n devops-lab get pods -l app=web-demo -o jsonpath='{.items[0].metadata.name}')
echo "$POD"
```

Delete it:

```bash
kubectl -n devops-lab delete pod "$POD"
kubectl -n devops-lab get pods -w
```

The Deployment/ReplicaSet should recreate a replacement Pod because the desired replica count remains unchanged.

## 9. Scale the Deployment

Scale to four replicas:

```bash
kubectl -n devops-lab scale deployment web-demo --replicas=4
kubectl -n devops-lab get deployment
kubectl -n devops-lab get pods -o wide
```

Optional practice:

```bash
kubectl -n devops-lab scale deployment web-demo --replicas=6
kubectl -n devops-lab get pods -o wide
kubectl -n devops-lab scale deployment web-demo --replicas=2
```

The important mindset is that you change desired state rather than manually creating or deleting individual Pods.

## 10. Rolling update

Change the application version variable:

```bash
kubectl -n devops-lab set env deployment/web-demo APP_VERSION=v2
kubectl -n devops-lab rollout status deployment/web-demo
kubectl -n devops-lab get pods -o wide
```

Verify:

```bash
for i in $(seq 1 10); do curl -s http://192.168.94.90:30080/; done
```

The Deployment strategy uses:

```yaml
maxUnavailable: 0
maxSurge: 1
```

This keeps required replicas available while allowing one temporary extra Pod during rollout.

## 11. Rollback

Show rollout history:

```bash
kubectl -n devops-lab rollout history deployment/web-demo
```

Rollback:

```bash
kubectl -n devops-lab rollout undo deployment/web-demo
kubectl -n devops-lab rollout status deployment/web-demo
curl -s http://192.168.94.90:30080/
```

## 12. Docker-to-Kubernetes command mindset

Docker:

```text
container → docker ps / docker logs / docker exec
```

Kubernetes:

```bash
kubectl -n devops-lab get pods
kubectl -n devops-lab logs deployment/web-demo
kubectl -n devops-lab exec -it deployment/web-demo -- /bin/sh
kubectl -n devops-lab describe deployment web-demo
kubectl -n devops-lab get deployment web-demo -o yaml
```

## 13. Service and EndpointSlice verification

```bash
kubectl -n devops-lab get service web-demo
kubectl -n devops-lab get endpointslices
kubectl -n devops-lab get endpointslices -l kubernetes.io/service-name=web-demo
kubectl -n devops-lab get pods --show-labels
```

If a Service exists but has no backend endpoints, verify that the Service selector matches the Pod labels.

## 14. Troubleshooting

### Pending Pod

```bash
kubectl -n devops-lab get pods
kubectl -n devops-lab describe pod <POD_NAME>
```

Check Events for scheduling, resource, volume, or node problems.

### ImagePullBackOff

```bash
kubectl -n devops-lab describe pod <POD_NAME>
systemctl status k3s --no-pager
journalctl -u k3s -n 100 --no-pager
journalctl -u k3s-agent -n 100 --no-pager
```

In this lab, proxy or registry connectivity is an important suspect.

### CrashLoopBackOff

```bash
kubectl -n devops-lab logs <POD_NAME>
kubectl -n devops-lab logs <POD_NAME> --previous
kubectl -n devops-lab describe pod <POD_NAME>
```

Review exit code, Events, command/args, environment variables, and probes.

### Service not reachable

```bash
kubectl -n devops-lab get pods,svc,endpointslices -o wide
kubectl -n devops-lab get pods --show-labels
kubectl -n devops-lab describe service web-demo
ss -lntup | grep 30080 || true
```

A missing `ss` listener alone does not prove that NodePort is broken because kube-proxy implementation details can differ.

### Node NotReady

```bash
kubectl get nodes
kubectl describe node dev-2
systemctl status k3s-agent --no-pager
journalctl -u k3s-agent -n 100 --no-pager
curl -k https://192.168.94.90:6443/
```

Check firewall, routing, VLAN connectivity, and TCP/6443.

### Flannel VXLAN

```bash
ss -lunp | grep 8472 || true
ip -br link
```

The nodes need UDP/8472 connectivity when using the default Flannel VXLAN backend.

## 15. Cleanup

Remove only the lesson resources while keeping the K3s cluster:

```bash
kubectl delete -f swarm/session-78-docker-to-kubernetes-mindset/k8s/web-demo.yaml
```

## Key interview points

1. A Pod is the smallest deployable Kubernetes unit.
2. A Deployment manages desired state for ReplicaSets and Pods.
3. A Service gives stable access to ephemeral Pods.
4. Readiness controls whether a Pod should receive traffic.
5. Liveness can trigger a container restart when the application is unhealthy.
6. Kubernetes does not require Docker Engine; K3s uses containerd by default.
7. Self-healing is driven by controllers reconciling actual state with desired state.
8. Rolling updates are controlled by Deployment strategy settings such as `maxUnavailable` and `maxSurge`.

## Safety notes

- Never commit the real K3s node token.
- Keep Kubernetes API access restricted to trusted networks.
- Keep Flannel VXLAN traffic restricted to cluster nodes.
- Verify network CIDR overlap before installing a cluster.
- The lab disables Traefik, ServiceLB, and Metrics Server intentionally to keep the scenario focused.

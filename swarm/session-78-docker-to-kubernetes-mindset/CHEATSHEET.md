# Session 78 — Command Cheat Sheet

Docker to Kubernetes Mindset

Source scope: commands used in this lesson only. Repeated identical commands are listed once. Replace placeholders such as `TOKEN_FROM_DEV_1` and `<POD_NAME>` before execution.

## Pre-check

1. Show the hostname.

```bash
hostname
```

2. Show local IP addresses.

```bash
hostname -I
```

3. Show interfaces in brief format.

```bash
ip -br addr
```

4. Show memory usage.

```bash
free -h
```

5. Show root filesystem usage.

```bash
df -h /
```

6. Show CPU count.

```bash
nproc
```

7. Show running Docker containers.

```bash
docker ps
```

8. Check whether Kubernetes-related ports are already in use.

```bash
ss -lntup | grep -E '(:6443|:10250|:30080)\b' || true
```

9. Check for conflicting K3s Pod or Service routes.

```bash
ip route | grep -E '10\.42\.|10\.43\.' || true
```

## Proxy

10. Configure HTTP proxy.

```bash
export HTTP_PROXY="http://192.168.95.204:2081"
```

11. Configure HTTPS proxy.

```bash
export HTTPS_PROXY="http://192.168.95.204:2081"
```

12. Configure proxy exclusions.

```bash
export NO_PROXY="127.0.0.1,localhost,192.168.0.0/16,10.42.0.0/16,10.43.0.0/16"
```

## K3s server

13. Install the pinned K3s server on DEV-1.

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='v1.36.4+k3s1' sh -s - server \
  --node-ip 192.168.94.90 \
  --disable traefik \
  --disable servicelb \
  --disable metrics-server
```

14. Check the K3s server service.

```bash
systemctl status k3s --no-pager
```

15. List Kubernetes nodes.

```bash
kubectl get nodes -o wide
```

16. List all Pods in all namespaces.

```bash
kubectl get pods -A
```

17. Read the K3s node token.

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

## K3s agent

18. Join DEV-2 to the cluster. Replace the token placeholder.

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='v1.36.4+k3s1' \
  K3S_URL='https://192.168.94.90:6443' \
  K3S_TOKEN='TOKEN_FROM_DEV_1' \
  sh -s - agent \
  --node-ip 192.168.94.91
```

19. Show cluster information.

```bash
kubectl cluster-info
```

20. List all Pods with node/IP details.

```bash
kubectl get pods -A -o wide
```

## Project path

21. Create the lesson directory.

```bash
sudo mkdir -p /opt/k8s-mindset
```

22. Enter the lesson directory.

```bash
cd /opt/k8s-mindset
```

23. Open the manifest in Nano.

```bash
sudo nano /opt/k8s-mindset/web-demo.yaml
```

## Manifest validation and deployment

24. Client-side validate the manifest without applying it.

```bash
kubectl apply --dry-run=client -f /opt/k8s-mindset/web-demo.yaml
```

25. Apply the manifest.

```bash
kubectl apply -f /opt/k8s-mindset/web-demo.yaml
```

26. Show the namespace.

```bash
kubectl get namespace devops-lab
```

27. Show the Deployment.

```bash
kubectl -n devops-lab get deployment
```

28. Show ReplicaSets.

```bash
kubectl -n devops-lab get rs
```

29. Show Pods with node/IP details.

```bash
kubectl -n devops-lab get pods -o wide
```

30. Show Services.

```bash
kubectl -n devops-lab get service
```

## Service tests

31. Test NodePort through DEV-1.

```bash
curl http://192.168.94.90:30080/
```

32. Test NodePort through DEV-2.

```bash
curl http://192.168.94.91:30080/
```

33. Send ten requests through DEV-1.

```bash
for i in $(seq 1 10); do curl -s http://192.168.94.90:30080/; done
```

## Self-healing

34. List Pods.

```bash
kubectl -n devops-lab get pods
```

35. Save the first matching Pod name into a shell variable.

```bash
POD=$(kubectl -n devops-lab get pods -l app=web-demo -o jsonpath='{.items[0].metadata.name}')
```

36. Print the selected Pod name.

```bash
echo "$POD"
```

37. Delete the selected Pod.

```bash
kubectl -n devops-lab delete pod "$POD"
```

38. Watch Pods until the replacement appears.

```bash
kubectl -n devops-lab get pods -w
```

## Scaling

39. Scale to four replicas.

```bash
kubectl -n devops-lab scale deployment web-demo --replicas=4
```

40. Scale to six replicas.

```bash
kubectl -n devops-lab scale deployment web-demo --replicas=6
```

41. Return to two replicas.

```bash
kubectl -n devops-lab scale deployment web-demo --replicas=2
```

## Rolling update

42. Change APP_VERSION to v2.

```bash
kubectl -n devops-lab set env deployment/web-demo APP_VERSION=v2
```

43. Wait for the Deployment rollout.

```bash
kubectl -n devops-lab rollout status deployment/web-demo
```

44. Send ten requests after the update.

```bash
for i in $(seq 1 10); do curl -s http://192.168.94.90:30080/; done
```

## Rollback

45. Show rollout revision history.

```bash
kubectl -n devops-lab rollout history deployment/web-demo
```

46. Roll back to the previous revision.

```bash
kubectl -n devops-lab rollout undo deployment/web-demo
```

47. Test the application after rollback.

```bash
curl -s http://192.168.94.90:30080/
```

## Common kubectl operations

48. Show Pods.

```bash
kubectl -n devops-lab get pods
```

49. Show logs for the Deployment.

```bash
kubectl -n devops-lab logs deployment/web-demo
```

50. Open a shell in one Pod selected through the Deployment.

```bash
kubectl -n devops-lab exec -it deployment/web-demo -- /bin/sh
```

51. Describe the Deployment.

```bash
kubectl -n devops-lab describe deployment web-demo
```

52. Print the Deployment object as YAML.

```bash
kubectl -n devops-lab get deployment web-demo -o yaml
```

## Service and EndpointSlice

53. Show the web-demo Service.

```bash
kubectl -n devops-lab get service web-demo
```

54. List EndpointSlices.

```bash
kubectl -n devops-lab get endpointslices
```

55. Show EndpointSlices for web-demo.

```bash
kubectl -n devops-lab get endpointslices -l kubernetes.io/service-name=web-demo
```

56. Show Pod labels.

```bash
kubectl -n devops-lab get pods --show-labels
```

57. Show Pod, Service, and EndpointSlice details together.

```bash
kubectl -n devops-lab get pods,svc,endpointslices -o wide
```

58. Describe the Service.

```bash
kubectl -n devops-lab describe service web-demo
```

## Troubleshooting

59. Describe a specific Pod.

```bash
kubectl -n devops-lab describe pod <POD_NAME>
```

60. Show K3s server logs.

```bash
journalctl -u k3s -n 100 --no-pager
```

61. Show K3s agent logs.

```bash
journalctl -u k3s-agent -n 100 --no-pager
```

62. Check the K3s agent service.

```bash
systemctl status k3s-agent --no-pager
```

63. Show current container logs for a Pod.

```bash
kubectl -n devops-lab logs <POD_NAME>
```

64. Show logs from the previous crashed container instance.

```bash
kubectl -n devops-lab logs <POD_NAME> --previous
```

65. Check NodePort visibility from the host.

```bash
ss -lntup | grep 30080 || true
```

66. Show nodes.

```bash
kubectl get nodes
```

67. Describe DEV-2.

```bash
kubectl describe node dev-2
```

68. Test connectivity to the Kubernetes API endpoint.

```bash
curl -k https://192.168.94.90:6443/
```

69. Check Flannel VXLAN UDP/8472.

```bash
ss -lunp | grep 8472 || true
```

70. Show network links.

```bash
ip -br link
```

## Cleanup

71. Delete the lesson manifest resources.

```bash
kubectl delete -f /opt/k8s-mindset/web-demo.yaml
```

## Safety notes

- Do not commit the real K3s node token.
- Verify CIDR overlap before K3s installation.
- Restrict TCP/6443 and UDP/8472 to trusted cluster networks.
- The delete command removes the resources defined by this lesson manifest.

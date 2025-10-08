This submission outlines the deployment of a highly available and scalable Kubernetes cluster. We've gone for a hands-on, self-managed Kubeadm setup, giving us full control, which is crucial for a production-grade environment.

This project specifically demonstrates:

Robust Infrastructure: Multi-node cluster using Kubeadm.

High Availability & Scalability: A Deployment running 3 replicas of a sample application.

Zero-Downtime Updates: Optimized Rolling Update configuration.

Edge Routing: NGINX Ingress Controller via Helm for external access.

We opted for a trio of Ubuntu 22.04 VMs for this setup: one control plane node (k8s-master) and two worker nodes (k8s-worker-1, k8s-worker-2).

1.1. Prerequisites (On ALL Nodes)
You must run these commands on all three VMs. We are using Containerd as the runtime and targeting Kubernetes v1.28.5 for a stable version.

Disable Swap (Mandatory):

Bash

sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
Enable required kernel modules and network settings:

Bash

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system
Install Containerd and K8s Components (v1.28.5):
(Follow the standard apt repository setup for containerd and Kubernetes.)

Bash

# Example commands for K8s components installation (use your actual repo setup)
sudo apt update && sudo apt install -y containerd.io
# Install kubelet, kubeadm, kubectl v1.28.5 (adjust version as needed)
sudo apt install -y kubelet=1.28.5-1.1 kubeadm=1.28.5-1.1 kubectl=1.28.5-1.1
sudo apt-mark hold kubelet kubeadm kubectl

# Configure containerd for systemd cgroup driver
sudo sh -c "containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/g' > /etc/containerd/config.toml"
sudo systemctl restart containerd
sudo systemctl enable containerd
1.2. Master Node Initialization (On k8s-master)
The cluster initialization uses Flannel, hence the 10.244.0.0/16 Pod CIDR.

Bash

# Initialize the control plane, ensuring the endpoint is correct
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --control-plane-endpoint=<MASTER_IP>

# Set up kubectl config for the current user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Deploy the Flannel CNI add-on (Note: We are using Flannel here)
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
1.3. Joining Worker Nodes
On the worker nodes, use the kubeadm join command that the master initialization step outputs.

Bash

# Example command - replace <token> and <hash> with your values!
sudo kubeadm join <MASTER_IP>:6443 --token <token> \
    --discovery-token-ca-cert-hash sha256:<hash>
2. Solution Deployment Steps
2.1. Deploy NGINX Ingress Controller (Using Helm)
Helm makes managing the complex Ingress Controller configuration a breeze.

Bash

# Add the official NGINX ingress chart repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install the controller. The service will default to NodePort on bare-metal.
helm install nginx-ingress ingress-nginx/ingress-nginx
2.2. Deploy Highly Available Application
We are deploying the NGINX app (manifests/sample-app.yaml) configured for High Availability (3 replicas) and using strict RollingUpdate parameters (maxUnavailable: 0) to guarantee zero downtime during version upgrades.

Bash

kubectl apply -f manifests/sample-app.yaml
2.3. Configure Local Access
To test the Ingress, you need the IP address of one of your cluster nodes (as the Ingress service is NodePort exposed).

Get Node IP: Find the public/private IP of any worker node.

Edit Hosts File: Map the hostname (myapp.local) to the node IP on your local system's /etc/hosts file:

<Worker_Node_IP> myapp.local
3. Design Decisions & Trade-offs (Engineering Note)
We chose the Kubeadm/Terraform approach over managed services (like EKS/GKE) for this assignment to demonstrate explicit control over the Kubernetes Control Plane lifecycle and to facilitate a bare-metal feel.

Image Choice: We used a specific, stable version (nginx:1.23.4-alpine) instead of latest for production stability and a smaller image footprint.

HA Database (Bonus): The PostgreSQL setup uses a single StatefulSet replica. While the design uses proper persistent storage, it is inherently non-HA and would typically require a specialized operator or external database service for a true production environment.

4. Verification & Deliverables
(Screenshots or command outputs would be included here)

Pods & Nodes Status
Bash

kubectl get nodes
# 
kubectl get pods -o wide
# [Image showing 3 running sample-app pods]
List of Services and Ingress
Bash

kubectl get svc
# [Image showing sample-app-service and nginx-ingress controller services]
kubectl get ingress
# [Image showing sample-app-ingress with myapp.local host]
Ingress Access Verification
(Screenshot showing the default NGINX welcome page when accessing http://myapp.local in a browser)
Kubernetes Production Environment Summary
This project delivers a Highly Available (HA) and scalable Kubernetes application stack, demonstrating best practices for production deployment using a self-managed Kubeadm cluster.

Component	    Provisioning Tool	HA Feature Implemented
Control Plane	Kubeadm / Terraform	External Load Balancer Endpoint (--control-plane-endpoint)
Application (Pods)	Kubectl	Pod Anti-Affinity (spread across nodes)
Availability	PDB	Pod Disruption Budget (minAvailable: 2)
Scaling/Updates	Deployment	Zero-Downtime Rolling Update (maxUnavailable: 0)
Routing	Helm / Ingress	NGINX Ingress Controller for external traffic


1. Cluster Setup Overview (HA Strategy)
The cluster is built on multiple VMs (min. 3 Masters, 2 Workers).

HA Provisioning : Infrastructure is automated using Terraform.

Control Plane HA: Master nodes are initialized using the load-balanced API endpoint (k8s-api.local:6443) and joined with the --control-plane flag to ensure etcd quorum and API server redundancy.

Networking: Flannel CNI is used with the Pod CIDR 10.244.0.0/16.

2. Deployment Steps
Assuming the cluster nodes are Ready, furthur steps:

2.1. Deploy Ingress Controller
Bash

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx
2.2. Deploy Application Stack (HA & Resiliency)
The stack includes the Deployment (3 replicas, Anti-Affinity), Service, Ingress, and PDB.

Bash

kubectl apply -f manifests/
2.3. Verification Access
Map the host to a worker node's IP for testing:

Bash

# Add to your local /etc/hosts:
<Worker_Node_IP> myapp.local
3. Verification & Deliverables
Showcasing the running HA components:

Check	Command	Purpose
Node Status	kubectl get nodes	Confirm all masters/workers are ready.
Pod Spread	kubectl get pods -l app=sample-app -o wide	Verify pods are on separate nodes (Anti-Affinity).
PDB Status	kubectl get pdb	Confirm the availability budget is active.
External Access	Access http://myapp.local	Verify routing via Ingress.


(Attach relevant images/screenshots demonstrating the successful output of these commands.)

4. Bonus Implementation
 Infrastructure setup is defined in the terraform/ directory.

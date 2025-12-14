# Project‑2: Application Deployment on AWS EKS with CI/CD and Monitoring

## 📖 Overview
This project demonstrates end‑to‑end deployment of a sample application using:
- **Docker** for containerization
- **Terraform** for infrastructure provisioning
- **Jenkins** for CI/CD pipeline automation
- **AWS EKS (Kubernetes)** for container orchestration
- **Prometheus + Grafana** for monitoring

---

## ⚙️ Prerequisites
- AWS account with IAM permissions
- Terraform installed
- Docker installed locally and on Jenkins EC2
- Jenkins EC2 instance with Git, Docker, kubectl, Helm
- GitHub repository for source code
- DockerHub account for image registry

---

## 🚀 Steps

### 1. Docker
```bash
docker build -t trend-app:latest .
docker run -p 3000:3000 trend-app:latest
docker tag trend-app:latest percianancy/trend-app:latest
docker push percianancy/trend-app:latest
```

---

### 2. Terraform
```bash
terraform init
terraform apply
```
*(main.tf defines VPC, IAM, EC2 for Jenkins, etc.)*

---

### 3. Kubernetes (AWS EKS)
```bash
eksctl create cluster --name project2-cluster --region ap-south-1 --nodes 2
aws eks --region ap-south-1 update-kubeconfig --name project2-cluster
kubectl get nodes
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

---

### 4. Jenkins CI/CD
- Install plugins: Docker, Git, Kubernetes, Pipeline.
- Install Docker, Git, kubectl on Jenkins EC2.
- Configure credentials for DockerHub, AWS, GitHub.
- Attach IAM role `ec2_jenkins_role` with `AdministratorAccess`.
- Pipeline stages:
  1. **Build** – compile/test app
  2. **Dockerize** – build & push image to DockerHub
  3. **Deploy** – apply manifests to EKS
  4. **Verify** – check pods/services

---

### 5. Monitoring (Prometheus + Grafana)
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
kubectl get pods -n monitoring
kubectl patch svc monitoring-grafana -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
kubectl patch svc monitoring-kube-prometheus-prometheus -n monitoring -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc -n monitoring
```

Grafana login:
```bash
kubectl get secret --namespace monitoring monitoring-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```
- Username: `admin`  
- Password: decoded secret

Import dashboards:
- 315 → Cluster
- 6417 → Node exporter
- 8588 → Pods

---

## Application LoadBalancer
```bash
kubectl get svc



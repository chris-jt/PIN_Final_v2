#!/bin/bash
set -e

# Función para esperar a que apt esté disponible
wait_for_apt() {
  while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 ; do
    echo "Esperando a que otras operaciones de apt terminen..."
    sleep 5
  done
}

handle_error() {
  echo "Error en la línea $1"
  exit 1
}

trap 'handle_error $LINENO' ERR

echo "Preparando el sistema..."
sudo mount -o remount,rw /

echo "Limpiando posibles bloqueos de apt..."
sudo rm -f /var/lib/apt/lists/lock
sudo rm -f /var/cache/apt/archives/lock
sudo rm -f /var/lib/dpkg/lock*

echo "Deshabilitando temporalmente command-not-found..."
sudo mv /usr/lib/cnf-update-db /usr/lib/cnf-update-db.bak || true
sudo touch /usr/lib/cnf-update-db
sudo chmod +x /usr/lib/cnf-update-db

echo "Limpiando y actualizando APT..."
sudo apt-get clean
sudo apt-get update --fix-missing

echo "Installing Unzip"
wait_for_apt
sudo apt-get update
sudo apt-get install -y unzip
unzip -v

echo "Installing AWS CLI"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install --update
aws --version

echo "installing transport-https"
#wait_for_apt
#sudo apt-get update && sudo apt-get install --validate=false apt-transport-https 

echo "Installing kubectl"
wait_for_apt
#sudo apt-get install -y kubectl
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.30.2/2024-07-12/bin/linux/amd64/kubectl
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin
echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc
kubectl version --client

#echo "Installing eksctl"
#curl --silent --location "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
#sudo mv /tmp/eksctl /usr/local/bin
#eksctl version

echo "Installing Docker"
wait_for_apt
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker

echo "Installing Docker Compose"
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

echo "Installing Helm"
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
helm version

# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Crear cluster EKS
echo "Creating EKS cluster..."
eksctl create cluster --name mi-cluster-eks --region us-east-1 --node-type t3.small --nodes 2

# Configurar kubectl
aws eks get-token --cluster-name mi-cluster-eks | kubectl apply -f -

echo "Cluster created successfully"

# Asegurarse de que las configuraciones estén disponibles para el usuario ubuntu
mkdir -p /home/ubuntu/.kube
mkdir -p /root/.kube
sudo cp /root/.kube/config /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config

# Añadir kubectl al PATH del usuario ubuntu
echo 'export PATH=$PATH:/usr/local/bin' >> /home/ubuntu/.bashrc
source /home/ubuntu/.bashrc

aws eks update-kubeconfig --region us-east-1 --name my-cluster-eks

echo "All necessary tools have been installed and cluster is ready."
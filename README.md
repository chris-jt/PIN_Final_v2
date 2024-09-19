# EKS Cluster with Nginx Deployment

This project automates the deployment of an EKS cluster and an Nginx service using GitHub Actions and AWS CloudFormation.

## Prerequisites

1. AWS account with appropriate permissions
2. GitHub repository
3. GitHub Actions enabled

## Setup

1. Fork this repository
2. In your GitHub repository settings, add the following secrets:
   - AWS_ACCESS_KEY_ID
   - AWS_SECRET_ACCESS_KEY
   - EC2_SSH_KEY (contents of your jenkins.pem file)

## Workflow

The GitHub Actions workflow will:

1. Create an EC2 instance using CloudFormation
2. Install necessary tools on the EC2 instance
3. Create an EKS cluster
4. Deploy Nginx to the cluster

## Connecting to the cluster with Lens from a remote Debian 12 PC

1. Install Lens on your Debian 12 PC:

curl -fsSL https://downloads.k8slens.dev/keys/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/lens-archive-keyring.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/lens-archive-keyring.gpg] https://downloads.k8slens.dev/apt/debian stable main" | sudo tee /etc/apt/sources.list.d/lens.list > /dev/null
sudo apt update
sudo apt install lens

2. Install AWS CLI on your Debian 12 PC:

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

3. Configure AWS CLI with your credentials:

aws configure

4. Update your kubeconfig to include the EKS cluster:

aws eks get-token --cluster-name mi-cluster-eks | kubectl apply -f -

5. Open Lens and add the cluster using the kubeconfig file (usually located at ~/.kube/config)

Now you should be able to manage your EKS cluster using Lens from your remote Debian 12 PC.

# Para conectarte a la instancia EC2 después de que el workflow se haya ejecutado:

1. Ve a la pestaña "Actions" en tu repositorio de GitHub.

2. Haz clic en la ejecución más reciente del workflow "Deploy EKS Cluster and Nginx".

3. En la sección "Artifacts", descarga el archivo "ssh-key-and-info".

4. Descomprime el archivo descargado. Encontrarás dos archivos:
        jenkins.pem: La clave privada SSH.
        connection_info.txt: Información sobre cómo conectarte.

5. Abre una terminal en tu máquina local.

6. Cambia los permisos de la clave privada:
    
    chmod 600 path/to/jenkins.pem

7. Utiliza el comando SSH proporcionado en connection_info.txt para conectarte:
    ssh -i path/to/jenkins.pem ubuntu@<EC2-PUBLIC-IP>
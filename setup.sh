#!/bin/bash

NAMESPACE="tcp-ip"
VALUES_LOKI="config/lokistack-values.yaml"

# Helm

echo -e "\nYou are installing Helm..."

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm -rf get_helm.sh

kubeconfig(){
    export KUBECONFIG=~/config/kubeconfig
    kubectl config use-context default
    kubectl get node -o wide
}

# k3s

echo -e "\nYou are installing k3s..."

sudo mkdir -p /etc/rancher/k3s
sudo cp config/config-k3s.yaml /etc/rancher/k3s/config.yaml
curl -sfL https://get.k3s.io | sh -
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chmod 666 ~/.kube/config
export KUBECONFIG=~/.kube/config
sleep 10

echo -e "Installation finished!"

# Manifests

echo -e "\nYou are applying the manifests..."

kubectl create namespace $NAMESPACE
kubectl apply -f manifest/emqx
kubectl apply -f manifest/influxdb
kubectl apply -f manifest/mysql
kubectl apply -f manifest/streamlit
kubectl apply -f manifest/telegraf
kubectl apply -f manifest/jenkins

# Loki-Stack

echo -e "Grafana's Installation\n"

# Add Helm repo and update
{
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update

    # Create Kubernetes namespace
    kubectl create namespace $NAMESPACE

    # Install/upgrade Loki stack
    helm upgrade --install loki grafana/loki-stack --namespace=$NAMESPACE --values $VALUES_LOKI

    # Wait for the Loki Grafana deployment to be ready
    kubectl rollout status deployment loki-grafana -n $NAMESPACE --timeout=210s
} > /dev/null 2>&1

# Check if the previous block executed successfully
if [ $? -eq 0 ]; then
    echo -e "The Loki stack has been deployed to your cluster. Loki can now be added as a datasource in Grafana."
else
    echo -e "An error occurred during the deployment of the Loki stack. Please check the logs for more details."
    exit 1
fi

# Retrieve and display Grafana admin password
echo -e "Admin's Password"
kubectl get secret loki-grafana --namespace=$NAMESPACE -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Grype

echo -e "\nYou are installing Grype..."

curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sudo sh -s -- -b /usr/local/bin

# Kubeseal

echo -e "\nYou are installing Kubeseal..."

KUBESEAL_VERSION='0.26.0'
curl -OL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION:?}/kubeseal-${KUBESEAL_VERSION:?}-linux-amd64.tar.gz"
tar -xvzf kubeseal-${KUBESEAL_VERSION:?}-linux-amd64.tar.gz kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal

# Kubescape

echo -e "\nYou are installing Kubescape..."

curl -s https://raw.githubusercontent.com/kubescape/kubescape/master/install.sh | /bin/bash
export PATH=$PATH:/home/<user>/.kubescape/bin 

# Velero

echo -e "\nYou are installing Velero..."

wget https://github.com/vmware-tanzu/velero/releases/download/v1.13.2/velero-v1.13.2-linux-amd64.tar.gz
tar -xvf velero-v1.13.2-linux-amd64.tar.gz
sudo mv velero-v1.13.2-linux-amd64/velero /usr/local/bin
rm -rf velero-v1.13.2-linux-amd64

echo -e "\nInstallation Finished"
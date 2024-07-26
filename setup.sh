#!/bin/bash

kubeconfig(){
    export KUBECONFIG=~/config/kubeconfig
    kubectl config use-context default
    kubectl get node -o wide
}

echo -e "\nYou are installing k3s with k3sup..."

sudo mkdir -p /etc/rancher/k3s

sudo cp config/config-k3s.yaml /etc/rancher/k3s/config.yaml

curl -sfL https://get.k3s.io | sh -

sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

sudo chmod 777 ~/.kube/config

export KUBECONFIG=~/.kube/config

echo -e "Installation finished!"

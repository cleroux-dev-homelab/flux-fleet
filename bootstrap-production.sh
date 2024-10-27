#!/usr/bin/env bash

###########################################
# ENV config
GIT_USER=cleroux-dev-homelab
GIT_REPOSITORY=flux-fleet
GIT_BRANCH=main

# Check if GITHUB_TOKEN is already set; if not, use sops to decrypt it
if [ -z "$GITHUB_TOKEN" ]; then
    GITHUB_TOKEN=$(sops -d ./github_token)
    export GITHUB_TOKEN
fi
###########################################

# Create the kind-cluster
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: production
nodes:
  - role: control-plane
  - role: worker
networking:
  disableDefaultCNI: true
  kubeProxyMode: none
  apiServerPort: $API_SERVER_PORT
EOF

# Installing cilium on the kind-cluster
helm repo add cilium https://helm.cilium.io/
docker pull quay.io/cilium/cilium:v1.15.5
kind load docker-image quay.io/cilium/cilium:v1.15.7

helm install cilium cilium/cilium --version 1.15.7 \
    --namespace kube-system \
    --set ipam.mode=kubernetes \
    --set socketLB.hostNamespaceOnly=true \
    --set kubeProxyReplacement=true \
    --set k8sServiceHost=production-control-plane \
    --set k8sServicePort=${API_SERVER_PORT}

# Bootstrapping the cluster
flux bootstrap git \
    --url=ssh://git@github.com/$GIT_USER/$GIT_REPOSITORY \
    --private-key-file=$PRIVATE_KEY_FILE \
    --password=$PRIVATE_KEY_PASSPHRASE \
    --branch=$GIT_BRANCH \
    --path=clusters/production

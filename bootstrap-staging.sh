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
nodes:
  - role: control-plane
    kubeadmConfigPatches:
    - |
      kind: InitConfiguration
      nodeRegistration:
        kubeletExtraArgs:
          node-labels: "ingress-ready=true"
    extraPortMappings:
    - containerPort: 80
      hostPort: 80
      protocol: TCP
    - containerPort: 443
      hostPort: 443
      protocol: TCP
EOF

# Bootstrapping the cluster
kubectl create ns flux-system
sops -d age.agekey |
    kubectl create secret generic sops-age \
        --namespace=flux-system \
        --from-file=age.agekey=/dev/stdin

flux bootstrap github \
    --components-extra=image-reflector-controller,image-automation-controller \
    --token-auth \
    --read-write-key \
    --owner=$GIT_USER \
    --repository=$GIT_REPOSITORY \
    --branch=$GIT_BRANCH \
    --path=clusters/staging

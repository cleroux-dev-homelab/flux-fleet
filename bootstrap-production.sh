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

# Creating the sops-age secret for in-cluster secret decryption
kubectl create ns flux-system
sops -d ./age.agekey |
    kubectl create secret generic sops-age \
        --namespace=flux-system \
        --from-file=age.agekey=/dev/stdin

# Bootstrapping the cluster using a GitHub PAT
flux bootstrap github \
    --registry=ghcr.io/fluxcd \
    --components-extra=image-reflector-controller,image-automation-controller \
    --owner=$GIT_USER \
    --repository=$GIT_REPOSITORY \
    --branch=$GIT_BRANCH \
    --token-auth \
    --path=clusters/production

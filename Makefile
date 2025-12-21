.DEFAULT_GOAL := help

SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c

export KUBECONFIG
export GITHUB_TOKEN

.SILENT: flux
.PHONY: flux
## Bootstrap fluxCD on the current-context cluster
flux:
	# Get CLUSTER_NAME from kubeconfig (fail if empty)
	CLUSTER_NAME="$$(kubectl config view -o yaml \
		| yq -r '. as $$cfg | .contexts[] | select(.name == $$cfg."current-context") | .context.cluster')"
	if [[ -z "$$CLUSTER_NAME" ]]; then
		echo "Failed to determine CLUSTER_NAME from current-context" >&2
		exit 1
	fi

	# Check if GITHUB_TOKEN is already set; if not, use sops to decrypt it
	if [ -z "$$GITHUB_TOKEN" ]; then
		GITHUB_TOKEN=$$(sops -d ./keys/github_token)
	fi

	kubectl create namespace flux-system --dry-run=client -o yaml | kubectl apply -f -

	sops -d ./keys/age.agekey | kubectl create secret generic sops-age \
			--dry-run=client -o yaml \
			--namespace=flux-system \
			--from-file=age.agekey=/dev/stdin | kubectl apply -f -

	# Bootstrapping the cluster using a GitHub PAT
	flux bootstrap github \
		--registry=ghcr.io/fluxcd \
		--components-extra=image-reflector-controller,image-automation-controller \
		--owner=cleroux-dev-homelab \
		--repository=flux-fleet \
		--branch=main \
		--token-auth \
		--path=clusters/production # TODO: use CLUSTER_NAME once local cluster is standardized

.PHONY: help
# From: https://gist.github.com/klmr/575726c7e05d8780505a
help:
	@echo "$$(tput sgr0)";sed -ne"/^## /{h;s/.*//;:d" -e"H;n;s/^## //;td" -e"s/:.*//;G;s/\\n## /---/;s/\\n/ /g;p;}" ${MAKEFILE_LIST}|awk -F --- -v n=$$(tput cols) -v i=15 -v a="$$(tput setaf 6)" -v z="$$(tput sgr0)" '{printf"%s%*s%s ",a,-i,$$1,z;m=split($$2,w," ");l=n-i;for(j=1;j<=m;j++){l-=length(w[j])+1;if(l<= 0){l=n-i-length(w[j])-1;printf"\n%*s ",-i," ";}printf"%s ",w[j];}printf"\n";}'


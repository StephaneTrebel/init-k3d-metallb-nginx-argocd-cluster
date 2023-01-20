#!/bin/env bash

set -e

# Parameters
ARGOCD_NAMESPACE=${1:-argocd}

# Retrieve default password setup by argocd
ADMIN_DEFAULT_PASSWORD=$(kubectl -n ${ARGOCD_NAMESPACE} get secret \
	argocd-initial-admin-secret \
	-o jsonpath="{.data.password}" | base64 -d; echo)

# Retrieve ArgoCD public IP exposed by the service LoadBalancer
ARGOCD_API_PUBLIC_API=$(kubectl get svc -n ${ARGOCD_NAMESPACE} argocd-server \
	--no-headers \
	-o json | jq ".status.loadBalancer.ingress[0].ip" | sed 's/"//g')

# Retrieve default password setup by argocd
argocd login ${ARGOCD_API_PUBLIC_API} \
	--insecure \
	--username admin \
	--password ${ADMIN_DEFAULT_PASSWORD}

# Generate a new password for ArgoCD admin account
# --force for idempotency
pass generate --force local/argocd/admin > /dev/null

# Update admin password
argocd account update-password \
	--account admin \
	--current-password ${ADMIN_DEFAULT_PASSWORD} \
	--new-password $(pass show local/argocd/admin)

# Remove now useless argocd default password secret
kubectl -n ${ARGOCD_NAMESPACE} delete secret argocd-initial-admin-secret

echo ArgoCD UI is now available on http://${ARGOCD_API_PUBLIC_API} !

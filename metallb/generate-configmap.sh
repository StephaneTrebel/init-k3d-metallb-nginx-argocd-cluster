#!/bin/env bash

set -e

# Args:
# - 1: k3d base cluster name (CLUSTER_NAME in Makefile)
# - 2: metallb namespace (METALLB_NAMESPACE in Makefile)
CLUSTER_NAME=${1:-default}
METALLB_NAMESPACE=${2:-metallb-system}

cidr_block=$(docker network inspect k3d-${CLUSTER_NAME} | jq '.[0].IPAM.Config[0].Subnet' | tr -d '"')
cidr_base_addr=${cidr_block%???}
ingress_first_addr=$(echo $cidr_base_addr | awk -F'.' '{print $1,$2,255,0}' OFS='.')
ingress_last_addr=$(echo $cidr_base_addr | awk -F'.' '{print $1,$2,255,255}' OFS='.')
INGRESS_RANGE=$ingress_first_addr-$ingress_last_addr

createConfigMapScript=$(mktemp)
metallbTempConfigMap=$(mktemp)
(
echo 'cat <<EOF'
cat metallb/config-map.yaml
echo 'EOF'
) >$createConfigMapScript
cat $createConfigMapScript

. $createConfigMapScript > $metallbTempConfigMap
rm -f $createConfigMapScript

cat $metallbTempConfigMap
kubectl apply -n ${METALLB_NAMESPACE} -f $metallbTempConfigMap
rm -f $metallbTempConfigMap

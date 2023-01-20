CLUSTER_NAME=local-cluster

.PHONY: create-local-cluster
create-local-cluster:
	k3d cluster create \
		$(CLUSTER_NAME) \
		--agents 3 \
		--k3s-arg "--disable=traefik@server:0" \
		--k3s-arg "--disable=servicelb@server:0" \
		--no-lb \
		--wait

.PHONY: delete-local-cluster
delete-local-cluster:
	k3d cluster delete $(CLUSTER_NAME)

.PHONY: install-metallb
install-metallb:
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml

.PHONY: configure-metallb
configure-metallb:
	metallb/generate-configmap.sh $(CLUSTER_NAME) metallb-system

.PHONY: install-nginx-ingress-controller
install-nginx-ingress-controller:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.2/deploy/static/provider/cloud/deploy.yaml

ARGOCD_NAMESPACE=argocd
.PHONY: install-argocd
install-argocd:
	kubectl create namespace $(ARGOCD_NAMESPACE) || true
	kubectl apply -n $(ARGOCD_NAMESPACE) -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.5.7/manifests/install.yaml
	# kubectl apply -n $(ARGOCD_NAMESPACE) -f argocd/ingress.yaml
	kubectl patch svc argocd-server -n $(ARGOCD_NAMESPACE) -p '{"spec":{"type":"LoadBalancer"}}'

ADMIN_PASSWORD=
.PHONY: configure-argocd
configure-argocd:
	argocd/configure-argocd.sh $(ARGOCD_NAMESPACE)


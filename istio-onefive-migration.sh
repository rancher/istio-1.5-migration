#!/bin/bash

set -e

ca=$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt | base64 -w 0)
token=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
namespace=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
server=https://kubernetes.default.svc
echo "
apiVersion: v1
kind: Config
clusters:
- name: default-cluster
  cluster:
    certificate-authority-data: ${ca}
    server: ${server}
contexts:
- name: default-context
  context:
    cluster: default-cluster
    namespace: istio-system
    user: default-user
current-context: default-context
users:
- name: default-user
  user:
    token: ${token}
" > sa.kubeconfig
kubectl config --kubeconfig=sa.kubeconfig use-context default-context

versions=$(kubectl get --ignore-not-found=true deploy istio-galley -n istio-system  -o=jsonpath='{$.spec.template.spec.containers[*].image}')
if [[ $versions == *"1.4"* || $versions == *"1.3"* ]]; then
	echo "Preparing for migration to Istio 1.5"
	kubectl delete --wait=true --timeout=20s --ignore-not-found=true deployment istio-galley -n istio-system
	kubectl delete --wait=true --timeout=20s --ignore-not-found=true validatingwebhookconfigurations.admissionregistration.k8s.io istio-galley
	kubectl delete --wait=true --timeout=20s --ignore-not-found=true serviceaccount istio-reader-service-account -n istio-system
	kubectl delete --wait=true --timeout=20s --ignore-not-found=true clusterrolebinding istio-reader
	sleep 2 # ensure webhook is gone or we get conflict errors
fi

echo "Istio 1.4 cleanup complete"

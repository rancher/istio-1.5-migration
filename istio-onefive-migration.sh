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

# purposely not checking galley deploy here in case the job is terminated and reruns
versions=$(kubectl get --ignore-not-found=true deploy istio-pilot -n istio-system  -o=jsonpath='{$.spec.template.spec.containers[*].image}')
if [[ $versions == *"1.4"* || $versions == *"1.3"* ]]; then
	echo "Preparing for migration to Istio 1.5"

  echo "Deleting galley deployment"
	kubectl delete --wait=true --timeout=20s --ignore-not-found=true deployment istio-galley -n istio-system
  c=0
  while [ "$(kubectl get pods --selector=app=galley -n istio-system --output json | jq -j '.items | length')" != "0" ] && [ $c -lt 20 ]; do
    echo "waiting for galley pods to terminate..."
    sleep 6
    c=$((c+1))
  done

  echo "Deleting galley validating webhook"
	kubectl delete --wait=true --timeout=20s --ignore-not-found=true validatingwebhookconfigurations.admissionregistration.k8s.io istio-galley
  c=0
  while [ "$(kubectl get validatingwebhookconfigurations.admissionregistration.k8s.io --field-selector=metadata.name=istio-galley --output json | jq -j '.items | length')" != "0" ] && [ $c -lt 5 ]; do
    echo "waiting for istio-galley validating webhook to terminate..."
    sleep 2
    c=$((c+1))
  done

  echo "Deleting istio-reader-service-account"
	kubectl delete --wait=true --timeout=20s --ignore-not-found=true serviceaccount istio-reader-service-account -n istio-system
  c=0
  while [ "$(kubectl get serviceaccount -n istio-system --field-selector=metadata.name=istio-reader-service-account --output json | jq -j '.items | length')" != "0" ] && [ $c -lt 5 ]; do
    echo "waiting for istio-reader-service-account to terminate..."
    sleep 2
    c=$((c+1))
  done

  echo "Deleting clusterrolebinding istio-reader"
	kubectl delete --wait=true --timeout=20s --ignore-not-found=true clusterrolebinding istio-reader
  c=0
  while [ "$(kubectl get clusterrolebinding --field-selector=metadata.name=istio-reader --output json | jq -j '.items | length')" != "0" ] && [ $c -lt 5 ]; do
    echo "waiting for istio-reader clusterrolebinding to terminate..."
    sleep 2
    c=$((c+1))
  done

  echo "Istio 1.4 cleanup complete"
else
  echo "Not a 1.4 migration, nothing to do."
fi

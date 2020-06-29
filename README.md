# istio-1.5-migration

Allows for helm upgrade migration from Istio 1.4 to Istio 1.5.

Several resources that were created by Istio components in <= 1.4.x were then added to the 1.5 manifests which causes a helm error. This removes them so they can be added by the new 1.5 helm charts.

Be aware there are complications with this approach, for instance removal of the `istio-reader-service-account` will remove its secrets and break various [multi-cluster installations](https://archive.istio.io/v1.4/docs/setup/install/multicluster/shared-vpn/#kubeconfig).

See the original issue for more information: https://github.com/istio/istio/issues/21648

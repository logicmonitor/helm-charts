# Logicmonitor Kubernetes Helm Charts
[![License](https://img.shields.io/github/license/logicmonitor/helm-charts)](https://github.com/logicmonitor/helm-charts/blob/master/LICENSE) ![Release Builds](https://github.com/logicmonitor/helm-charts/actions/workflows/release.yml/badge.svg?branch=main) ![Pages Build Deployment](https://github.com/logicmonitor/helm-charts/actions/workflows/pages/pages-build-deployment/badge.svg) [![Releases downloads](https://img.shields.io/github/downloads/logicmonitor/helm-charts/total.svg)](https://github.com/logicmonitor/helm-charts/releases)
<br>

Helm repository for LogicMonitor's kubernetes helm charts

## Usage

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

Once Helm is set up properly, add the repo as follows:

```console
helm repo add logicmonitor https://logicmonitor.github.io/helm-charts
```

You can then run `helm search repo logicmonitor` to see the charts.

# VERSION SKEW MATRIX
## Argus Releases
| name | version | appVersion | dependencies |
| :---- | :---- | :---- | :---- |
| argus | [2.0.0-rc2](https://github.com/logicmonitor/helm-charts/releases/tag/argus-2.0.0-rc2) | [v8.0.0-rc1](https://hub.docker.com/r/logicmonitor/argus/tags?page=1&name=v8.0.0-rc1) | <ul> <li>kube-state-metrics@4.7.0 https://prometheus-community.github.io/helm-charts</li> </ul> | 
| argus | [2.0.0-rc1](https://github.com/logicmonitor/helm-charts/releases/tag/argus-2.0.0-rc1) | [v8.0.0-rc1](https://hub.docker.com/r/logicmonitor/argus/tags?page=1&name=v8.0.0-rc1) | <ul> <li>kube-state-metrics@4.7.0 https://prometheus-community.github.io/helm-charts</li> </ul> | 

## Collectorset Controller Releases
| name | version | appVersion | dependencies |
| :---- | :---- | :---- | :---- |
| collectorset-controller | [1.0.0-rc2](https://github.com/logicmonitor/helm-charts/releases/tag/collectorset-controller-1.0.0-rc2) | [v4.0.0-rc1](https://hub.docker.com/r/logicmonitor/collectorset-controller/tags?page=1&name=v4.0.0-rc1) | <ul>  </ul> | 
| collectorset-controller | [1.0.0-rc1](https://github.com/logicmonitor/helm-charts/releases/tag/collectorset-controller-1.0.0-rc1) | [v4.0.0-rc1](https://hub.docker.com/r/logicmonitor/collectorset-controller/tags?page=1&name=v4.0.0-rc1) | <ul>  </ul> | 

## LM Container Releases
| name | version | appVersion | dependencies |
| :---- | :---- | :---- | :---- |
| lm-container | [1.0.0-rc2](https://github.com/logicmonitor/helm-charts/releases/tag/lm-container-1.0.0-rc2) |  | <ul> <li>argus@2.0.0-rc1 https://logicmonitor.github.io/helm-charts</li><li>collectorset-controller@1.0.0-rc2 https://logicmonitor.github.io/helm-charts</li> </ul> | 
| lm-container | [1.0.0-rc1](https://github.com/logicmonitor/helm-charts/releases/tag/lm-container-1.0.0-rc1) |  | <ul> <li>argus@2.0.0-rc1 https://logicmonitor.github.io/helm-charts</li><li>collectorset-controller@1.0.0-rc1 https://logicmonitor.github.io/helm-charts</li> </ul> | 

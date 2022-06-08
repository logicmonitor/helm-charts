# VERSION SKEW MATRIX
## Argus Releases
| name | version | appVersion | dependencies | Compatible Kubernetes Versions |
| :---- | :---- | :---- | :---- | :---- |
| argus | [3.0.0-ea](https://github.com/logicmonitor/helm-charts/releases/tag/argus-3.0.0-ea) | [v8.0.0-ea](https://hub.docker.com/r/logicmonitor/argus/tags?page=1&name=v8.0.0-ea) | <ul> <li>kube-state-metrics@4.7.0 https://prometheus-community.github.io/helm-charts</li> </ul> | >= 1.14.0-0 | 

## Collectorset Controller Releases
| name | version | appVersion | dependencies | Compatible Kubernetes Versions |
| :---- | :---- | :---- | :---- | :---- |
| collectorset-controller | [2.0.0-ea](https://github.com/logicmonitor/helm-charts/releases/tag/collectorset-controller-2.0.0-ea) | [v4.0.0-ea](https://hub.docker.com/r/logicmonitor/collectorset-controller/tags?page=1&name=v4.0.0-ea) | <ul>  </ul> | >= 1.14.0-0 | 

## LM Container Releases
| name | version | appVersion | dependencies | Compatible Kubernetes Versions |
| :---- | :---- | :---- | :---- | :---- |
| lm-container | [1.0.0-ea](https://github.com/logicmonitor/helm-charts/releases/tag/lm-container-1.0.0-ea) |  | <ul> <li>argus@3.0.0-ea https://logicmonitor.github.io/helm-charts</li><li>collectorset-controller@2.0.0-ea https://logicmonitor.github.io/helm-charts</li> </ul> |  | 

# helm-charts
Helm repository for LogicMonitor helm charts

```bash
$ helm repo add logicmonitor https://logicmonitor.github.io/helm-charts
```

Find index.yaml of this repository [here](https://logicmonitor.github.io/helm-charts/index.yaml)

## Argus Releases
| name | version | appVersion | dependencies |
| :---- | :---- | :---- | :---- |
| argus | 2.0.0-rc2 | v8.0.0-rc1 | <ul> <li>kube-state-metrics@4.7.0 https://prometheus-community.github.io/helm-charts</li> </ul> | 
| argus | 2.0.0-rc1 | v8.0.0-rc1 | <ul> <li>kube-state-metrics@4.7.0 https://prometheus-community.github.io/helm-charts</li> </ul> | 

## Collectorset Controller Releases
| name | version | appVersion | dependencies |
| :---- | :---- | :---- | :---- |
| collectorset-controller | 1.0.0-rc2 | v4.0.0-rc1 | <ul>  </ul> | 
| collectorset-controller | 1.0.0-rc1 | v4.0.0-rc1 | <ul>  </ul> | 

## LM Container Releases
| name | version | appVersion | dependencies |
| :---- | :---- | :---- | :---- |
| lm-container | 1.0.0-rc2 |  | <ul> <li>argus@2.0.0-rc1 https://logicmonitor.github.io/helm-charts</li><li>collectorset-controller@1.0.0-rc2 https://logicmonitor.github.io/helm-charts</li> </ul> | 
| lm-container | 1.0.0-rc1 |  | <ul> <li>argus@2.0.0-rc1 https://logicmonitor.github.io/helm-charts</li><li>collectorset-controller@1.0.0-rc1 https://logicmonitor.github.io/helm-charts</li> </ul> | 

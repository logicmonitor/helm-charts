# Contribution guidelines

First of all: Thank you! We really appreciate your efforts to make helm-charts better ❤️

Create or find an issue you would like to implement:
-   issues with the label [helm-wanted](https://github.com/logicmonitor/helm-charts/labels/help%20wanted) are ready to be picked up and implemented.
-   review the existing issues and ensure that you are not going to create a duplicate
-   create your issue and wait for comments from maintainers
-   once the issue is discussed and assigned to you – feel free to implement

## Developing helm-charts

1.  Prepare project (Install [Chart-Releaser](https://github.com/helm/chart-releaser))

    ```sh
    git clone https://github.com/logicmonitor/helm-charts
    cd helm-charts
    
    cr package charts/<chart-name>
    ```

2.  Make sure that chart installs on Kubernetes Cluster and respective application works fine
    ```sh
    helm upgrade --install -f <configration-values.yaml-file-path> <chart-name> .cr-release-packages/<chart-name>-<version-built>.tgz
    ```

3.  Update necessary documents if needed – Readme etc.

4.  Submit pull request

5.  Make sure all the checks are passing

6.  Wait for maintainers to review the code

7.  Thanks for you contribution :smile:

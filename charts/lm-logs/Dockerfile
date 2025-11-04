FROM fluent/fluentd-kubernetes-daemonset:v1.16-debian-forward-1

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libsystemd-dev \
      pkg-config \
      ruby-dev && \
    gem install fluent-plugin-systemd -v 1.1.1 && \
    gem install fluent-plugin-lm-logs -v 1.2.8 && \
    gem install fluent-plugin-multi-format-parser -v 1.0.0 && \
    apt-get purge -y \
      build-essential \
      libsystemd-dev \
      pkg-config \
      ruby-dev && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
#!/bin/bash
set -eux
cd {{lein_service_app_dir}}
export JAVA_OPTS="-Xmx{{lein_service_xmx_mb_value}}m"

# force java8 (see roles/openjdk8_install)
export PATH=$PATH:/usr/lib/jvm/java-8-openjdk-amd64/bin
export JAVA_CMD=/usr/lib/jvm/java-8-openjdk-amd64/bin/java

lein with-profile production trampoline run \
    >> {{lein_service_log_dir}}/console.log 2>&1

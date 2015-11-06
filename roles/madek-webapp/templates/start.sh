#!/bin/bash
set -eux
source /etc/profile.d/rbenv-load.sh
cd {{madek_webapp_dir}}
rbenv-load
rbenv shell {{rubies.jruby.version}}

# Rails Settings
export RAILS_ENV={{rails_env}}
export export RAILS_RELATIVE_URL_ROOT="{{madek_web_context_or_empty}}"
export MADEK_ROOT_DIR="{{madek_root_dir}}"

# Memory Settings
export JVM_OPTS="-Xmx{{webapp_xmx_value}}"
# it seems that the above is ignored,
# we could either invoke `jruby -J-Xmx4G` or set JRUBY_OPTS
export JRUBY_OPTS="-J-Xms{{webapp_xmx_value}} -J-Xmx{{webapp_xmx_value}}"

bundle exec puma config.ru -t 4:40 -b tcp://127.0.0.1:{{madek_webapp_port}} \
  >> {{madek_webapp_log_dir}}/{{madek_webapp_service_name}}.log 2>&1

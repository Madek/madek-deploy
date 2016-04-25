#!/bin/bash
set -eux
cd {{madek_admin_dir}}

export PATH=$(pwd)/vendor/jruby/bin/:$PATH

# Rails Settings
export RAILS_ENV={{rails_env}}
export export RAILS_RELATIVE_URL_ROOT="{{madek_web_context_or_empty}}"
export MADEK_ROOT_DIR="{{madek_root_dir}}"

# Memory Settings
# we could either invoke `jruby -J-Xmx4G` or set JRUBY_OPTS
export JRUBY_OPTS=" -J-Xmx{{admin_xmx_mb_value}}m "

bundle exec puma config.ru -t 4:40 -b tcp://127.0.0.1:{{madek_admin_port}} \
  >> {{madek_admin_log_dir}}/{{madek_admin_service_name}}.log 2>&1

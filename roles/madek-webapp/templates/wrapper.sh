#!/bin/bash
mkdir -p {{madek_webapp_log_dir}}
chown -R {{madek_user}} {{madek_webapp_log_dir}}
sudo -u {{madek_user}} -n -i {{madek_webapp_service_bin}}

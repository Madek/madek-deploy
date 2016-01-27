#!/bin/bash
mkdir -p {{madek_admin_log_dir}}
chown -R {{madek_user}} {{madek_admin_log_dir}}
sudo -u {{madek_user}} -n -i {{madek_admin_service_bin}}

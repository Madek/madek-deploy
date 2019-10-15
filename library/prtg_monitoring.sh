#!/bin/sh -e

####################################################################################################
# Ansible module to pause and enable PRTG devices
#
# Example Usage with 2 devices and delegation to another node,
# which must be able to reach the API, might not be the case for controlled node (firewall!)
#
# ```yaml
# - prtg_monitoring:
#     api_url: "https://prtg.example.com"
#     api_user: "adamadm"
#     api_passhash: "1234567890"
#     device_id: "{{item}}"
#     paused: yes
#     pause_message: "auto-deploy" # optional
#     pause_minutes: 120 # optional
#   loop: ["18604", "18607"]
#   delegate_to: localhost
# ```
#
# Installation: copy the shell script file to your local ansible repo/inventory,
# in a `library` subfolder. Make a note where it was copied from so you can check for updates.
#
# Development Docs:
# - https://www.paessler.com/manuals/prtg/http_api
# - https://docs.ansible.com/ansible/2.8/dev_guide/developing_modules_best_practices.html
# - https://docs.ansible.com/ansible/2.8/reference_appendices/common_return_values.html
####################################################################################################

# NOTE: for ansible modules the first argument is the path to a text file, containing the arguments.
. $1

# * global vars for simpler output handling.
# * `stdout` is only returned in case of error or debug or verbose level >= 2
msg="-"
api_call="-"
rc="-1"
stdout="-"

escape_for_json() {
  printf '%s' "$(printf '%s' "$1" | python -c 'import json,sys; print json.dumps(sys.stdin.read())')";
}
escape_for_url_param() {
  printf '%s' "$(printf '%s' "$1" | python -c 'import urllib,sys; print urllib.quote(sys.stdin.read())')";
}
return_message() {
  # NOTE: positional args are: msg, changed, failed, stdout
  printf '{"changed": %s, "failed": %s, "msg": %s, "invocation": %s, "rc": %s, "stdout": %s}' \
  "$2" "$3" \
  "$(escape_for_json "$1")" \
  "$(escape_for_json "$api_call")" \
  "$rc" \
  "$(escape_for_json "$4")"
}
# success_message() { return_message "$1" "true" "false" "-"; }
success_message() {
  local _stdout=""
  if { test "$_ansible_debug" = "true" || test "$_ansible_verbosity" -ge 2 ;} then _stdout="$stdout"; fi
  return_message "$1" "true" "false" "$_stdout";
}
fail_message() { return_message "$1" "false" "true" "$stdout"; }
fail_with_message() { fail_message "$1"; exit 1; }

normalize_yaml_bool() { # as per https://yaml.org/type/bool.html
  local bool
  local truthies="y Y yes Yes YES true True TRUE on On ON"
  local falsies="n N no No NO false False FALSE off Off OFF"
  for str in $truthies; do test "$1" = "$str" && bool=true; done
  for str in $falsies; do test "$1" = "$str" && bool=false; done
  if test -z "$bool"; then
    printf "invalid boolean value '${1}' for argument '${2}'"
    return 1
  fi
  printf $bool
}
check_integer() {
  if { test -z "$1" || test "$1" -ge 0 ;} then
    printf $1
  else
    printf "invalid integer value '${1}' for argument '${2}'"
    return 1
  fi
}

if test ! -x $(which curl); then
  fail_with_message 'could not find `curl` command!'
fi

# check required args
test -z "$api_url" && fail_with_message "missing required arguments: api_url"
test -z "$api_user" && fail_with_message "missing required arguments: api_user"
test -z "$api_passhash" && fail_with_message "missing required arguments: api_passhash"
test -z "$device_id" && fail_with_message "missing required arguments: device_id"
test -z "$paused" && fail_with_message "missing required arguments: paused"

# defaults
test -z "$pause_message" && pause_message="deploy with ansible"

# check/normalize/escape args
paused="$(normalize_yaml_bool "$paused" "paused")" || fail_with_message "$paused"
api_url="$(printf '%s' "$api_url" | sed 's:/*$::')"
api_user="$(escape_for_url_param "$api_user")"
api_passhash="$(escape_for_url_param "$api_passhash")"
device_id="$(escape_for_url_param "$device_id")"
pause_message="$(escape_for_url_param "$pause_message")"
pause_minutes="$(check_integer "$pause_minutes" "pause_minutes")" || fail_with_message "$pause_minutes"
_ansible_debug="$(normalize_yaml_bool "$_ansible_debug" "_ansible_debug")" || fail_with_message "$_ansible_debug"

#  build the api call
api_path="pause.htm"
api_params="?id=${device_id}&username=${api_user}&passhash=${api_passhash}"

if test "$paused" = "false"; then
  api_params="${api_params}&action=1"
  msg="Device is now enabled"
else
  api_params="${api_params}&action=0"
  msg="Device is now paused"
  if test ! -z "$pause_message"; then
    api_params="${api_params}&pausemsg=${pause_message}"
  fi
  if test "$pause_minutes" -gt 0; then
    api_path="pauseobjectfor.htm"
    api_params="${api_params}&duration=${pause_minutes}"
    msg="Device is now paused for ${pause_minutes} minutes"
  fi
fi
api_call="${api_url}/api/${api_path}${api_params}"

stdout="$(curl -v -s --fail "$api_call" 2>&1)"
rc="$?"

if test "$rc" = 0; then
  success_message "$msg"
  exit 0
else
  fail_with_message "something went wrong!"
fi

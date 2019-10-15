# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.define 'madek'
  # config.vm.define 'madek-ubuntu'
  config.vm.hostname = "madek.example.com"

  # base box
  config.vm.box = "bento/debian-9"
  # config.vm.box = "bento/ubuntu-16.04"

  # ports - prod
  config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # https://superuser.com/a/1182104
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  config.vm.provision "shell", inline: <<-SHELL
    # apt-get update
    # apt-get install -y -f curl build-essential libssl-dev default-jdk ruby git
  SHELL

  # dont automatically check for updates
  config.vm.box_check_update = false
end

#!/usr/bin/env ruby
# WANT_JSON

require 'json'
require 'openssl'
require 'open3'
require 'yaml'

def exec! cmd
  Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
    stdin.close()
    out = stdout.read
    err = stderr.read
    exit_status = wait_thr.value
    unless exit_status.success?
      abort out + err
    else
      out
    end
  end
end

def tag
  release = YAML.load_file("../config/releases.yml")['releases'].first
  tag = "#{release['version_major']}.#{release['version_minor']}.#{release['version_patch']}" \
    + ( release['version_pre'] ?  "-#{release['version_pre']}" : "")
end

def build_is_latest_release
  `cd .. && test $(git rev-parse HEAD) == $(git rev-parse origin/release) && echo 'true' || echo 'false'`
end

def tree_id
  exec!('cd .. && git log -n 1 --pretty=%T').strip
end

def check_url! url
  exec! " curl -sS --fail -I '#{url}'"
end

def check_and_build_urls base_url
  begin
    ['madek.tar.gz', 'madek.tar.gz.sig'].map{|name|
      base_url + "/" + name
    }.map{ |url|
      check_url!(url) && url
    }
  rescue Exception => e
    nil
  end
end

@args = JSON.parse(File.open(ARGV[0]).read) rescue {}

def find_urls
  if base_url = @args['base_url']
    check_and_build_urls base_url
  else
    check_and_build_urls("https://github.com/Madek/madek/releases/download/#{tag}") \
    || check_and_build_urls("https://ci.zhdk.ch/cider-ci/storage/tree-attachments/#{tree_id}")
  end
end


begin
  if urls = find_urls
    print JSON.dump(
      "args" => @args,
      "changed" => false,
      "urls" => urls,
      "build_is_latest_release" => build_is_latest_release,
      "stdout" => "Archive and signature found."
    )
  else
    raise 'no urls'
  end
rescue Exception => e
  print JSON.dump(
    "args" => @args,
    "changed" => false,
    "urls" => nil,
    "stdout" => "Warning: archive or signature missing! #{e}"
  )
end

exit 0

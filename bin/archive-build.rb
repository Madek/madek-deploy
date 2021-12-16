#!/usr/bin/env ruby

require 'yaml'
require 'open3'
require 'pry'
require 'active_support/all'
require 'fileutils'

APP_NAME='madek'
RAILS_SERVICES= %w(webapp admin-webapp graphql-api)

DEPLOY_DIR= Pathname.new(File.dirname(File.absolute_path(__FILE__))).join("..").to_s
SOURCE_DIR= File.absolute_path("#{DEPLOY_DIR}/..")
CONFIG_DIR= File.absolute_path("#{SOURCE_DIR}/config")
BUILD_DIR= File.absolute_path("#{DEPLOY_DIR}/tmp/#{APP_NAME}")
BUILD_CONFIG_DIR= File.absolute_path("#{BUILD_DIR}/config")

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

def clean
  FileUtils.rm_r BUILD_DIR, :force => true
end

def tree_id
  @tree_id ||= Dir.chdir(SOURCE_DIR) do
    exec!("git log -1 --pretty=%T").strip
  end
end

def commit_id
  @commit_id ||= Dir.chdir(SOURCE_DIR) do
    exec!("git log -1 --pretty=%H").strip
  end
end

def datalayer_tree_id
  @datalayer_tree_id ||= Dir.chdir(SOURCE_DIR) do
    exec!("cd webapp/datalayer && git log -1 --pretty=%T").strip
  end
end

def changes_since_release
  @changes_since_release ||= Dir.chdir(SOURCE_DIR) do
    exec!('./dev/release-notes').strip
  end
end

def deploy_info
  {
    tree_id: tree_id,
    commit_id: commit_id,
    datalayer_tree_id: datalayer_tree_id,
    build_time: Time.now.utc.as_json#,
    # changes_since_release: changes_since_release
  }
end

def prepare
  clean
  FileUtils.mkdir_p BUILD_DIR
  IO.write("#{BUILD_DIR}/tree_id", tree_id)
  FileUtils.mkdir_p "#{BUILD_DIR}/config"
  IO.write("#{BUILD_DIR}/config/deploy-info.yml", deploy_info.as_json.to_yaml)
  print " prepared, ..."
end

def build_config_dir
  print "building config dir ... "
  FileUtils.mkdir_p BUILD_CONFIG_DIR
  FileUtils.cp "#{CONFIG_DIR}/settings.yml", BUILD_CONFIG_DIR
  FileUtils.cp "#{CONFIG_DIR}/releases.yml", BUILD_CONFIG_DIR
  print " done, "
end

def copy_git_repo_files source_dir_name, target_dir_name = source_dir_name
  FileUtils.mkdir_p "#{BUILD_DIR}/#{target_dir_name}"
  sub_source_dir = "#{SOURCE_DIR}/#{source_dir_name}"
  Dir.exist?(sub_source_dir) || raise("No directory #{sub_source_dir}")
  exec! <<-CMD.strip_heredoc
    #!/usr/bin/env bash
    set -eux
    cd #{sub_source_dir}
    #{DEPLOY_DIR}/bin/git-archive-all -- - \
      | tar x --directory #{BUILD_DIR}/#{target_dir_name}
  CMD
end

def build_documentation_dir
  print "building documentation ... "
  copy_git_repo_files "documentation"
  print "done, "
end

def build_api_documentation_dir
  print "building api documentation ... "
  copy_git_repo_files "api/docs"
  print "done, "
end

def build_api_browser_dir
  print "building api browser dir... "
  copy_git_repo_files "api/resources/browser", "api/browser"
  print "done, "
end

def build_api
  print "building api ... "
  exec! <<-CMD.strip_heredoc
    #!/usr/bin/env bash
    set -eux
    cd #{SOURCE_DIR}/api
    ./bin/uberjar
  CMD
  FileUtils.cp "#{SOURCE_DIR}/api/madek-api.jar", "#{BUILD_DIR}/api/api.jar"
  print "done, "
end



def build_rails_services
  RAILS_SERVICES.each do |service|
    print "building #{service} ... "
    copy_git_repo_files service
    print "done, "
  end
end

def pack build_archive
  print "pack archive ... "
  exec! <<-CMD.strip_heredoc
    #!/usr/bin/env bash
    set -eux
    cd #{BUILD_DIR}
    cd ..
    tar cfz #{DEPLOY_DIR}/#{build_archive} #{APP_NAME}
  CMD
  print "done, "
end

def verify_archive
  clean
  begin
    exec! "bin/archive-verify"
    exec! "tar xvfz #{APP_NAME}.tar.gz -C tmp #{APP_NAME}/tree_id"
    IO.read("#{BUILD_DIR}/tree_id") == tree_id
  rescue Exception => e
    nil
  end
end

def main
  build_archive = "#{APP_NAME}.tar.gz"
  clean
  if verify_archive
    print "existing archive #{build_archive} is intact"
  else
    print "building #{build_archive} ..."
    prepare
    build_config_dir
    build_rails_services
    build_api_documentation_dir
    build_api_browser_dir
    build_api
    pack build_archive
    puts " done "
  end
end

main()

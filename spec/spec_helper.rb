require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", __FILE__)

require "rubygems"
require "bundler"
Bundler.setup(:default, :test)

$:.unshift(File.expand_path("../../lib", __FILE__))

require "rspec/core"
require "rspec/its"

require "tmpdir"
require "archive/zip"

# bosh_cli
require "cli"

require "bosh/workspace"
require "bosh/workspace/tasks"

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

# load all files in spec/support/* (but not lower down)
Dir[File.dirname(__FILE__) + '/support/*/*.rb'].each do |path|
  require path unless File.directory?(path)
end

def files_match(filename, expected_filename)
  file = File.read(filename)
  expected_file = File.read(expected_filename)
  file.should == expected_file
end

def yaml_files_match(filename, expected_filename)
  yaml = YAML.load_file(filename)
  expected_yaml = YAML.load_file(expected_filename)
  yaml.should == expected_yaml
end

def setup_home_dir
  home_dir = File.expand_path("../../tmp/home", __FILE__)
  FileUtils.rm_rf(home_dir)
  FileUtils.mkdir_p(home_dir)
  ENV['HOME'] = home_dir
end

# returns the file path to a file
# in the fake $HOME folder
def home_file(*path)
  File.join(ENV['HOME'], *path)
end

def in_home_dir(&block)
  FileUtils.chdir(home_file, &block)
end

def get_tmp_file_path(content, file_name="tmp")
  tmp_file = File.open(File.join(Dir.mktmpdir, file_name), "w")
  tmp_file.write(content)
  tmp_file.close
  tmp_file.path
end

def asset_dir(*path)
  assets_dir = File.expand_path("../assets", __FILE__)
  File.join(assets_dir, *path)
end

def asset_file(*path)
  assets_file = File.expand_path("../assets", __FILE__)
  IO.read(File.join(assets_file, *path))
end

def extracted_asset_dir(name, *path)
  zipped_file = asset_dir(*path)
  target_dir = File.expand_path("../../tmp/#{name}", __FILE__)
  FileUtils.rm_rf(target_dir) if File.exist?(target_dir)
  FileUtils.mkdir_p(target_dir)
  Archive::Zip.extract(zipped_file, target_dir)
  target_dir
end

def project_root
  File.expand_path('../../', __FILE__)
end

require "yaml"
require "membrane"

module Bosh::Workspace
  module Tasks; end
end

require "bosh/workspace/shell"
require "bosh/workspace/tasks/bosh_command_runner.rb"
require "bosh/workspace/tasks/deployment.rb"

rake_paths = File.expand_path('tasks/**/*.rake', File.dirname(__FILE__))
Dir.glob(rake_paths).each { |r| import r  }

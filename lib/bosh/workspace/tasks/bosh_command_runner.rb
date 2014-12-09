module Bosh::Workspace::Tasks
  class BoshCommandRunner
    attr_reader :target, :username, :password, :deployment_file

    def initialize(target, username, password)
      @target = target
      @username = username
      @password = password
      @shell = Bosh::Workspace::Shell.new
    end      

    def run(command, options = {})
      options.merge! default_options
      deployment_file = options.delete(:deployment_file)
      args = ['-n', '-t', target]
      args.concat ['-d', deployment_file] if deployment_file
      @shell.run "bundle exec bosh #{args.join(' ')} #{command}", options
    end

    private

    def default_options
      {
        output_command: true,
        env: { "BOSH_USER" => username, "BOSH_PASSWORD" => password }
      }
    end
  end
end

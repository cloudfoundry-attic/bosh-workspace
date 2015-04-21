module Bosh::Workspace
  class BoshCommandContext
    attr_reader :target, :username, :password
    attr_accessor :deployment_file

    def initialize(target, username, password, deployment)
      @target = target
      @username = username
      @password = password
      @deployment = deployment
    end

    def new(command_class)
      command_class.new.tap do |cmd|
        options.each { |k, v| cmd.add_option k.to_sym, v  }
      end
    end

    private

    def options
      {
        non_interactive: true,
        target: @target,
        username: @username,
        password: @password,
        deployment: @deployment
      }
    end
  end
end

module Bosh::Workspace
  module WorkspaceDeploymentsHelper
    def with_deployment_context
      deployments.each do |deployment|
        set_context(deployment)
        yield deployment
      end
    end

    def bosh_prepare_deployment
      @context.new(Bosh::Cli::Command::Prepare).prepare
    end

    def bosh_deploy
      @context.new(Bosh::Cli::Command::ProjectDeployment).deploy
    end

    def bosh_run_errand(errand)
      @context.new(Bosh::Cli::Command::Errand).run_errand(errand)
    end

    def deployments
      unless File.exists? deployments_file
        err "Could not find Deployments file: #{deployments_file}"
      end

      @deployments ||= begin
        YAML.load_file(deployments_file).map { |d| Deployment.new(d)  }
      end
    end

    private

    def set_context(deployment)
      args = %i(target username password merged_file)
             .map { |a| deployment.send(a) }
      @context = BoshCommandContext.new(*args)
    end

    def deployments_file
      File.join(work_dir, "deployments.yml")
    end
  end
end

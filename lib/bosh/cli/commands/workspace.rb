require "bosh/workspace"

module Bosh::Cli::Command
  class Workspace < Base
    include Bosh::Workspace
    include WorkspaceDeploymentsHelper

    usage "workspace deploy"
    desc "Deploy according to the current workspace directory"
    def deploy_workspace
      with_deployment_context do
        bosh_prepare_deployment
        bosh_deploy
      end

      with_deployment_context do |deployment|
        deployment.errands.each do |errand|
          bosh_run_errand(errand)
        end
      end
    end
  end
end

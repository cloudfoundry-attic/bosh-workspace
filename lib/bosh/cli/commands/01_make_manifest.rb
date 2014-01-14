require "bosh/manifests"

module Bosh::Cli::Command
  class Manifests < Base
    include Bosh::Cli::Validation
    include Bosh::Manifests

    usage "manifests"
    desc "Show the list of available manifests"
    def manifests
      setup_manifest_manager

      nl
      say(@manifest_manager.to_table)
      nl
    end

    usage "build manifest"
    desc "Create manifest (assumes current directory to be a manifests repo)"
    def build_manifest(name)
      setup_manifest_manager
      manifest = @manifest_manager.find(name)
      result_path = Bosh::Manifests::ManifestBuilder.build(manifest, work_dir)
      say("Manifest build succesfull: '#{result_path}'")
    end

    # Hack to unregister original deploy command
    Bosh::Cli::Config.instance_eval("@commands.delete('deploy')")

    usage "deploy"
    desc "Deploy according to the currently selected deployment manifest"
    option "--recreate", "recreate all VMs in deployment"
    def deploy
      setup_manifest_manager
      # build current deployment manifest
      deployment_cmd(options).perform
    end

    private

    def setup_manifest_manager
      @manifest_manager = Bosh::Manifests::ManifestManager.discover(work_dir)
      @manifest_manager.validate_manifests
    end

    def deployment_cmd(options = {})
      cmd ||= Bosh::Cli::Command::Deployment.new
      options.each do |key, value|
        cmd.add_option key.to_sym, value
      end
      cmd
    end
  end
end

require "bosh/manifests"

module Bosh::Cli::Command
  class Manifests < Base
    include Bosh::Cli::Validation
    include Bosh::Manifests

    # Hack to unregister original deployment command
    Bosh::Cli::Config.instance_eval("@commands.delete('deployment')")

    usage "deployment"
    desc "Get/set current deployment"
    def deployment(filename = nil)
      unless filename.nil?
        manifest = DeploymentManifest.new(find_deployment(filename))

        unless manifest.valid?
          say("Validation errors:".make_red)
          manifest.errors.each do |error|
            say("- #{error}")
          end
          err("'#{filename}' is not valid".make_red)
        end
      end

      deployment_cmd(options).set_current(filename)
    end

    usage "prepare deployment"
    desc "Resolve and upload required releases and stemcells"
    def prepare
      current_deployment.releases.each do |release|
        release.resolve
        release.upload unleass stemcell.exists?
      end

      current_deployment.stemcells.each do |stemcell|
        stemcell.upload unleass stemcell.exists?
      end
    end

    # Hack to unregister original deploy command
    Bosh::Cli::Config.instance_eval("@commands.delete('deploy')")

    usage "deploy"
    desc "Deploy according to the currently selected deployment manifest"
    option "--recreate", "recreate all VMs in deployment"
    def deploy
      # setp(build current deployment manifest
      # manifest = @manifest_manager.find(name)
      # result_path = Bosh::Manifests::ManifestBuilder.build(manifest, work_dir)
      deployment_cmd(options).perform
    end

    private

    def deployment_cmd(options = {})
      cmd ||= Bosh::Cli::Command::Deployment.new
      options.each do |key, value|
        cmd.add_option key.to_sym, value
      end
      cmd
    end
  end
end

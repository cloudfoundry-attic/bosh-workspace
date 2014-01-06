require "bosh/manifests"

module Bosh::Cli::Command
  class Manifests < Base
    include Bosh::Cli::Validation
    include Bosh::Manifests

    usage "manifests"
    desc "Show the list of available manifests"
    def manifests
      manifest_manager = Bosh::Manifests::ManifestManager.discover(work_dir)
      manifest_manager.print_manifests
    end


    usage "make manifest"
    desc "Create manifest (assumes current directory to be a manifests repo)"
    def make_manifest(name = nil)

    end
  end
end

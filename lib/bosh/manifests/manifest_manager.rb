module Bosh::Manifests
  class ManifestManager
    attr_reader :manifests

    def self.discover(work_dir)
      manifests_dir = File.join(work_dir, "manifests")

      unless File.exists? manifests_dir
        err "Missing manifests directory in '#{work_dir}'"
      end

      manifest_files = Dir.glob(File.join(manifests_dir, "*.yml"))
      ManifestManager.new(manifest_files)
    end

    def initialize(manifest_files)
      @manifests = []
      manifest_files.each do |manifest_file|
        manifest = Bosh::Manifests::Manifest.new(manifest_file)
        manifest.validate
        @manifests << manifest
      end
    end

    def print_manifests

    end

  end
end

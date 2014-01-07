module Bosh::Manifests
  class ManifestManager
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
        @manifests << Bosh::Manifests::Manifest.new(manifest_file)
      end
    end

    def validate_manifests(options = {})
      @manifests.each do |manifest|
        unless manifest.valid?
          say("Validation errors:".make_red)
          manifest.errors.each do |error|
            say("- #{error}")
          end
          err("'#{manifest.filename}' is not a valid manifest".make_red)
        end
      end
    end

    def to_table
      manifests_table = table do |t|
        headings = ["Name", "File"]
        t.headings = headings
        @manifests.each do |manifest|
          t << [manifest.name, manifest.filename]
        end
      end
    end

    def find(name)
      manifest = @manifests.select { |m| m.name == name }.pop
      err("Could not find manifest: '#{name}'") unless manifest
      manifest
    end
  end
end

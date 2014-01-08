module Bosh::Manifests
  class ManifestBuilder
    include Bosh::Manifests::SpiffHelper

    def self.build(manifest, work_dir)
      manifest_builder = ManifestBuilder.new(manifest, work_dir)
      manifest_builder.merge_templates
    end

    def initialize(manifest, work_dir)
      @manifest = manifest
      @work_dir = work_dir
    end

    def merge_templates
      spiff_merge spiff_template_paths, target_file
    end

    private

    def spiff_template_paths
      spiff_templates = template_paths
      # spiff_templates << meta_file
    end

    def template_paths
      @manifest.templates.map { |t| template_path(t) }
    end

    def meta_file

    end

    def target_file
      File.join(@work_dir, ".generated_manifests", "#{@manifest.name}.yml")
    end

    def template_path(template)
      path = File.join(@work_dir, "templates", template)
      err("Template does not exist: #{template}") unless File.exists? path
      path
    end
  end
end

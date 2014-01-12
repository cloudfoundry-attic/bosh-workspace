module Bosh::Manifests
  class ManifestBuilder
    include Bosh::Manifests::SpiffHelper

    def self.build(manifest, work_dir)
      manifest_builder = ManifestBuilder.new(manifest, work_dir)
      manifest_builder.merge_templates
      manifest_builder.target_file
    end

    def initialize(manifest, work_dir)
      @manifest = manifest
      @work_dir = work_dir
    end

    def merge_templates
      spiff_merge spiff_template_paths, target_file
    end

    def target_file
      hidden_file_path(:manifests)
    end

    private

    def spiff_template_paths
      spiff_templates = template_paths
      spiff_templates << meta_file_path
    end

    def template_paths
      @manifest.templates.map { |t| template_path(t) }
    end

    def meta_file_path
      path = hidden_file_path(:meta)
      File.open(path, 'w') { |file| file.write(meta_file_content) }
      path
    end

    def meta_file_content
      {
        "director_uuid" => @manifest.director_uuid,
        "meta" => @manifest.meta
      }.to_yaml
    end

    def hidden_file_path(type)
      File.join(hidden_dir_path(type), "#{@manifest.name}.yml")
    end

    def hidden_dir_path(name)
      dir = File.join(@work_dir, ".#{name.to_s}")
      Dir.mkdir(dir) unless File.exists? dir
      dir
    end

    # TODO move to template validator which should have access to @work_dir
    def template_path(template)
      path = File.join(@work_dir, "templates", template)
      err("Template does not exist: #{template}") unless File.exists? path
      path
    end
  end
end

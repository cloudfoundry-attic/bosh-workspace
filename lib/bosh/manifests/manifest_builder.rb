module Bosh::Manifests
  class ManifestBuilder
    include Bosh::Manifests::SpiffHelper

    def self.build(manifest, work_dir)
      manifest.deployments.each do |dep_manifest|
        say "Merging templates for depended deployment: #{dep_manifest.name}"
        ManifestBuilder.new(dep_manifest, work_dir).merge_templates
      end
      say "Merging templates for deployment: #{manifest.name}"
      ManifestBuilder.new(manifest, work_dir).merge_templates
    end

    def initialize(manifest, work_dir)
      @manifest = manifest
      @work_dir = work_dir
    end

    def merge_templates
      spiff_merge spiff_template_paths, target_file
      @manifest.merged_file = target_file
    end

    private

    def target_file
      @target_file ||= hidden_file_path(:manifests)
    end

    def spiff_template_paths
      spiff_templates = template_paths
      spiff_templates << stub_file_path # make sure releases are resolved
      spiff_templates.concat dependend_deployment_paths
      spiff_templates << stub_file_path # use uuid from stub
    end

    def template_paths
      @manifest.templates.map { |t| template_path(t) }
    end

    def dependend_deployment_paths
      @manifest.deployments.map { |d| d.merged_file }
    end

    def stub_file_path
      @stub_file_path ||= begin
        path = hidden_file_path(:stubs)
        File.open(path, 'w') { |file| file.write(stub_file_content) }
        path
      end
    end

    def stub_file_content
      {
        "director_uuid" => @manifest.director_uuid,
        "releases" => filterd_releases,
        "meta" => @manifest.meta
      }.to_yaml
    end

    def filterd_releases
      allowed_keys = %w[name version]
      @manifest.releases.map do |release|
        release.select { |key| allowed_keys.include?(key) }
      end
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

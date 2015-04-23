module Bosh::Workspace
  class WorkspacePatch
    include Bosh::Cli::Validation
    attr_reader :deployments, :templates_ref

    def self.create(deployments, templates_dir)
      if File.exist? File.join(templates_dir, '.git')
        ref = Rugged::Repository.new(templates_dir).head.target.oid
      end
      deployments = deployments.map do |name, file|
        YAML.load_file(file)
          .select{ |k| %w(stemcells releases).include? k }
          .merge!({ 'name' => name })
      end
      new(deployments, ref)
    end

    def self.from_file(patch_file)
      a = YAML.load_file patch_file
      new(a["deployments"], a["templates_ref"])
    end

    def initialize(deployments, templates_ref)
      @deployments = deployments
      @templates_ref = templates_ref
    end

    def perform_validation(options = {})
      Schemas::WorkspacePatch.new.validate to_hash
    rescue Membrane::SchemaValidationError => e
      errors << e.message
    end

    def to_hash
      { "deployments" => deployments }
        .tap { |h| h["templates_ref"] = templates_ref if templates_ref }
    end

    def to_yaml
      to_hash.to_yaml
    end

    def to_file(patch_file)
      IO.write(patch_file, to_yaml)
    end

    def apply(deployment_files, templates_dir)
      checkout_submodule(templates_dir, templates_ref) if templates_ref
      deployment_files.each do |name, file|
        out = YAML.load_file(file)
              .merge!(deployment(name))
        IO.write(file, out.to_yaml)
      end
    end

    def changes(patch)
      out = {}

      ds = patch.deployments.inject({}) do |out, d|
        name = d['name']
        changes = hash_changes(
          normalized_deployment(name),
          patch.normalized_deployment(name)
        )
        out[name] = changes if changes
        out
      end

      out['deployments'] = ds unless ds.empty?

      unless templates_ref.nil? || templates_ref == patch.templates_ref
        out["templates_ref"] = ref_changes(templates_ref, patch.templates_ref)
      end
      out
    end

    def changes?(patch)
      !changes(patch).empty?
    end

    def normalized_deployment(name)
      normalized = deployment(name)
      %w(releases stemcells).each do |section|
        normalized[section] = normalized[section].inject({}) do |acc, e|
          acc.tap { |a| a[e["name"]] = e }
        end
      end
      normalized
    end

    def deployment(name)
      deployments.find { |d| d['name'] == name }
        .select{ |k| %w(stemcells releases).include? k }
    end

    private

    def changeset(old, new)
      cs = Bosh::Cli::HashChangeset.new
      cs.add_hash(old, :old)
      cs.add_hash(new, :new)
      cs
    end

    def ref_changes(old, new)
      Bosh::Cli::HashChangeset.new.diff(old[0..6], new[0..6], '  ')
    end

    def hash_changes(old, new)
      cs = changeset(old, new)
      cs.changed? ? cs.summary.join("\n") : nil
    end

    def checkout_submodule(dir, ref)
      repo = Rugged::Repository.new(dir)
      repo.checkout ref, strategy: :force
    end
  end
end

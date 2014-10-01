require "git"
require "hashdiff"
module Bosh::Workspace
  class DeploymentPatch
    attr_reader :stemcells, :releases, :templates_ref

    def self.create(deployment_file, templates_dir)
      ref = Git.open(templates_dir).log(1).first.sha
      deployment = YAML.load_file deployment_file
      new(deployment["stemcells"], deployment["releases"], ref)
    end

    def self.from_file(patch_file)
      a = YAML.load_file patch_file
      new(a[:stemcells], a[:releases], a[:templates_ref])
    end

    def initialize(stemcells, releases, templates_ref)
      @stemcells = stemcells
      @releases = releases
      @templates_ref = templates_ref
    end

    def to_yaml
      {
        stemcells: stemcells,
        releases: releases,
        templates_ref: templates_ref
      }.to_yaml
    end

    def to_file(patch_file)
      IO.write(patch_file, to_yaml)
    end

    def apply(deployment_file, templates_dir)
      Git.open(templates_dir).checkout(templates_ref)
      deployment = YAML.load_file deployment_file
      deployment.merge! 'stemcells' => stemcells, 'releases' => releases
      IO.write(deployment_file, deployment.to_yaml)
    end

    def changes(patch)
      {
        stemcells: item_changes(stemcells, patch.stemcells),
        releases: item_changes(releases, patch.releases),
        templates_ref: item_changes(templates_ref, patch.templates_ref)
      }.reject { |_, v| v.empty? }
    end

    def changes?(patch)
      !changes(patch).empty?
    end

    private

    def item_changes(old, new)
      old, new = presentify_item(old), presentify_item(new)
      changes = HashDiff.diff(old, new).map { |a| a.join(' ').squeeze(' ') }
      presentify_changes(changes).join(', ')
    end

    def presentify_changes(changes)
      translations = { '~' => "changed", '-' => 'removed', '+' => 'added' }
      changes.map { |l| l.gsub(/^./) { |m| translations.fetch(m, m) } }
    end

    def presentify_item(item)
      item.is_a?(Array) ? versions_hash(item) : item[0..6]
    end

    def versions_hash(array)
      Hash[array.map { |v| [v["name"], v["version"]]}]
    end
  end
end

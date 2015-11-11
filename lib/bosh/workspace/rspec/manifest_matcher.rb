RSpec::Matchers.define :match_manifest do |expected|
  match do |actual|
    @diff = Bosh::Cli::HashChangeset.new
    @diff.add_hash(normalize_and_load_deployment_manifest(actual), :new)
    @diff.add_hash(normalize_and_load_deployment_manifest(expected), :old)
    !@diff.changed?
  end

  failure_message do |actual|
    @diff.summary.join("\n")
  end

  private

  def normalize_and_load_deployment_manifest(manifest_file)
    manifest_hash = YAML.load_file manifest_file
    Bosh::Cli::DeploymentManifest.new(manifest_hash).normalize
  end
end

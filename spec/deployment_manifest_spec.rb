describe Bosh::Workspace::DeploymentManifest do
  let(:project_deployment) { Bosh::Workspace::DeploymentManifest.new manifest_file }
  let(:manifest_file) { get_tmp_file_path(manifest.to_yaml, file_name) }
  let(:file_name) { "foo.yml" }
  let(:name) { "foo" }
  let(:uuid) { "e55134c3-0a63-47be-8409-c9e53e965d5c" }
  let(:domain_name) { "bosh" }
  let(:templates) { ["path_to_bar", "path_to_baz"] }
  let(:releases) { [
    { "name" => "foo", "version" => release_version, "git" => "example.com/foo.git" }
  ] }
  let(:release_version) { 1 }
  let(:meta) { { "foo" => "bar" } }
  let(:manifest) { {
    "name" => name,
    "director_uuid" => uuid,
    "domain_name" => domain_name,
    "templates" => templates,
    "releases" => releases,
    "meta" => meta,
  } }

  subject { project_deployment }

  describe "#perform_validation" do
    subject { project_deployment.errors.first }
    let(:invalid_manifest) do
      if defined?(missing)
        manifest.delete_if { |key| Array(missing).include?(key) }
      else
        manifest
      end
    end
    let(:manifest_file) { get_tmp_file_path(invalid_manifest.to_yaml) }

    before do
      project_deployment.validate
      expect(project_deployment).to_not be_valid
    end

    context "not a hash" do
      let(:invalid_manifest) { "foo" }
      it { should match(/Expected instance of Hash/) }
    end

    %w(name director_uuid releases templates meta).each do |field_name|
      context "missing #{field_name}" do
        let(:missing) { field_name }
        it { should match(/#{field_name}.*missing/i) }
      end
    end

    context "optional domain_name" do
      let(:missing) { ["domain_name", "director_uuid"] }
      it { should match(/director_uuid/) }
      it { should_not match(/domain_name/) }
    end

    context "director_uuid" do
      context "invalid" do
        let(:uuid) { "invalid_uuid" }
        it { should match(/director_uuid.*doesn't validate/) }
      end

      context "current" do
        let(:uuid) { "current" }
        let(:missing) { "name" }
        it { should_not match(/director_uuid/) }
        it { should match(/name/) }
      end
    end

    context "releases" do
      let(:invalid_manifest) do
        manifest["releases"].map! { |r| r.delete_if { |key| Array(missing).include?(key) } }
        manifest
      end

      %w(name version git).each do |field_name|
        context "missing #{field_name}" do
          let(:missing) { field_name }
          it { should match(/#{field_name}.*missing/i) }
        end
      end

      context "latest version" do
        let(:missing) { "git" }
        let(:release_version) { "latest" }
        it { should match(/git.*missing/i) }
        it { should_not match(/version/i) }
      end
    end
  end

  describe "#director_uuid=" do
    before { subject.director_uuid = "foo-bar" }
    its(:director_uuid) { should eq "foo-bar" }
  end

  describe "property readers" do
    it "has properties" do
      expect(subject.name).to eq name
      expect(subject.director_uuid).to eq uuid
      expect(subject.domain_name).to eq domain_name
      expect(subject.templates).to eq templates
      expect(subject.releases).to eq releases
      expect(subject.meta).to eq meta
    end
  end

  describe "#merged_file" do
    it "creates parent directory" do
      dir = File.dirname(subject.merged_file)
      expect(File.directory?(dir)).to be_true
    end

    it "retruns merged file" do
      expect(subject.merged_file).to match(/\.deployments\/#{file_name}/)
    end
  end
end

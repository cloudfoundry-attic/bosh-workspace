describe Bosh::Manifests::DeploymentManifest do
  subject do
    Bosh::Manifests::DeploymentManifest.new manifest_file, deployments_enabled
  end
  let(:manifest_file) { get_tmp_file_path(manifest.to_yaml) }
  let(:deployments_enabled) { true }
  let(:name) { "foo" }
  let(:uuid) { "foo-bar-uuid" }
  let(:deployments) { [ deployment ] }
  let(:deployment) { "child-deployment.yml" }
  let(:templates) { ["path_to_bar", "path_to_baz"] }
  let(:releases) { [
    { "name" => "foo", "version" => "latest", "git" => "example.com/foo.git" }
  ] }
  let(:meta) { { "foo" => "bar" } }
  let(:manifest) { {
    "name" => name,
    "director_uuid" => uuid,
    "deployments" => deployments,
    "templates" => templates,
    "releases" => releases,
    "meta" => meta,
  } }

  describe "#validate" do
    let(:validation_manifest) { manifest.tap { |m| m.delete(missing) } }
    let(:manifest_file) { get_tmp_file_path(validation_manifest.to_yaml) }

    before do
      subject.validate
    end

    context "missing name" do
      let(:missing) { "name" }
      it "set error" do
        expect(subject.errors).to eq ["Manifest should contain a name"]
      end
    end

    context "missing director_uuid" do
      let(:missing) { "director_uuid" }
      it "set error" do
        expect(subject.errors).to eq ["Manifest should contain a director_uuid"]
      end
    end

    context "missing templates" do
      let(:missing) { "templates" }
      it "set error" do
        expect(subject.errors).to eq ["Manifest should contain templates"]
      end
    end

    context "missing releases" do
      let(:missing) { "releases" }
      it "set error" do
        expect(subject.errors).to eq ["Manifest should contain releases"]
      end
    end

    context "missing meta" do
      let(:missing) { "meta" }
      it "set error" do
        expect(subject.errors).to eq ["Manifest should contain meta hash"]
      end
    end

    context "optional deployments" do
      let(:missing) { "deployments" }
      it { should be_valid }
    end

    context "invalid deployments" do
      let(:deployments) { "not-an-array" }
      let(:missing) { "none" }
      it "set error" do
        expect(subject.errors).to eq ["Manifest: deployments should be array"]
      end
    end
  end

  describe "properties" do
    it "has properties" do
      subject.validate
      expect(subject).to be_valid
      expect(subject.name).to eq name
      expect(subject.director_uuid).to eq uuid
      expect(subject.templates).to eq templates
      expect(subject.releases).to eq releases
      expect(subject.meta).to eq meta
    end
  end

  describe "#initialize" do
    context "not a hash" do
      let(:manifest) { "foo" }
      it "raises an error" do
        expect{subject}.to raise_error "Manifest should be a hash"
      end
    end

    context "deployments not enable" do
      let(:deployments_enabled) { false }
      it "raises an error" do
        expect{subject}.to raise_error "Recursive deployments not supported"
      end
    end

    context "no deployments" do
      let(:manifest) { {} }
      it "does not raise an error" do
        expect{subject}.to_not raise_error
      end
    end
  end

  describe "#deployments" do
    let(:deployments_enabled) { true }
    let(:dep_deployment) { instance_double("DeploymentManifest") }

    it "inits deployments" do
      subject
      Bosh::Manifests::DeploymentManifest.should_receive(:new)
        .with(/\/#{deployment}/, false).and_return(dep_deployment)
      expect(subject.deployments).to include dep_deployment
    end
  end
end

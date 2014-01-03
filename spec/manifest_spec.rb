describe Bosh::Manifests::Manifest do
  subject { Bosh::Manifests::Manifest.new manifest_file }
  let(:manifest_file) { get_tmp_file_path(manifest) }
  let(:name) { "foo" }
  let(:manifests) { ["path_to_bar", "path_to_baz"] }
  let(:meta) { { "foo" => "bar" } }
  let(:manifest) {
    { "name" => name, "manifests" => manifests, "meta" => meta }.to_yaml
  }

  context "invalid manifest" do
    context "not a hash" do
      let(:manifest) { "foo" }
      it "raises an error" do
        subject.validate
        expect(subject).to_not be_valid
        expect(subject.errors).to eq ["Manifest should be a hash"]
      end
    end

    context "missing name" do
      let(:manifest) { { "manifests" => manifests, "meta" => meta }.to_yaml }
      it "raises an error" do
        subject.validate
        expect(subject).to_not be_valid
        expect(subject.errors).to eq ["Manifest should contain a valid name"]
      end
    end

    context "missing manifests" do
      let(:manifest) { { "name" => name, "meta" => meta }.to_yaml }
      it "raises an error" do
        subject.validate
        expect(subject).to_not be_valid
        expect(subject.errors).to eq ["Manifest should contain manifests"]
      end
    end

    context "missing meta" do
      let(:manifest) { { "name" => name, "manifests" => manifests }.to_yaml }
      it "raises an error" do
        subject.validate
        expect(subject).to_not be_valid
        expect(subject.errors).to eq ["Manifest should contain meta hash"]
      end
    end

  end

  context "valid manifest" do
    it { should be_valid }
  end
end

describe Bosh::Manifests::ManifestBuilder do
  let(:manifest) { instance_double("Bosh::Manifests::Manifest") }
  let(:work_dir) { asset_dir("manifests-repo") }
  let(:target_name) { "bar" }
  let(:target_file) {
    File.join(work_dir, ".generated_manifests", "#{target_name}.yml") }

  describe ".build" do
    subject { Bosh::Manifests::ManifestBuilder.build manifest, work_dir }
    let(:manifest_builder) {
      instance_double("Bosh::Manifests::ManifestBuilder") }

    it "creates builder and merges templates" do
      Bosh::Manifests::ManifestBuilder.should_receive(:new)
        .with(manifest, work_dir).and_return(manifest_builder)
      manifest_builder.should_receive(:merge_templates)
        .and_return(target_file)
      expect(subject).to eq target_file
    end
  end

  describe "#merge_templates" do
    subject { Bosh::Manifests::ManifestBuilder.new manifest, work_dir }
    let(:templates) { ["foo.yml"] }
    let(:template_path) { File.join(work_dir, "templates/foo.yml" ) }
    let(:template_exists) { true }

    before do
      manifest.should_receive(:templates).and_return(templates)
      File.should_receive(:exists?).with(template_path)
        .and_return(template_exists)
    end

    context "missing template" do
      let(:template_exists) { false }
      it "raises error" do
        expect{ subject.merge_templates }.to raise_error /does not exist/
      end
    end

    context "template exists" do
      it "generates manifest with spiff" do
        subject.should_receive(:spiff_merge).with([template_path], target_file)
        manifest.should_receive(:name).and_return(target_name)
        subject.merge_templates
      end
    end
  end
end

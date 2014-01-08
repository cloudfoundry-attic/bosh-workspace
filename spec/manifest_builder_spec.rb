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
    let(:template_path) { File.join(work_dir, "templates/foo.yml") }
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
      let(:target_dir) { File.join(work_dir, ".generated_manifests" ) }
      let(:target_dir_exists) { true }

      before do
        File.should_receive(:exists?).with(target_dir)
          .and_return(target_dir_exists)
        manifest.should_receive(:name).and_return(target_name)
        subject.should_receive(:spiff_merge)
          .with([template_path], target_file)
      end

      context "missing target dir" do
        let(:target_dir_exists) { false }

        it "creates target dir" do
          Dir.should_receive(:mkdir).with(target_dir)
          subject.merge_templates
        end
      end

      context "target dir exists" do
        it "generates manifest with spiff" do
          Dir.should_not_receive(:mkdir)
          subject.merge_templates
        end
      end
    end
  end
end

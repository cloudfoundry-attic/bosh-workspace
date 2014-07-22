describe Bosh::Workspace::ManifestBuilder do
  let(:manifest) { instance_double("Bosh::Workspace::Manifest",
    name: "bar",
    director_uuid: "foo-bar-uuid",
    stemcells: [ { "name" => "foo", "version" => "2"} ],
    releases: [ { "name" => "foo", "version" => "latest", "git" => "release_repo.git" } ],
    templates: ["foo.yml"],
    meta: { "foo" => "bar" },
    merged_file: ".deployments/foo.yml")
  }
  let(:work_dir) { asset_dir("manifests-repo") }

  describe ".build" do
    subject { Bosh::Workspace::ManifestBuilder.build manifest, work_dir }
    let(:manifest_builder) {
      instance_double("Bosh::Workspace::ManifestBuilder") }

    it "creates builder and merges templates" do
      Bosh::Workspace::ManifestBuilder.should_receive(:new)
        .with(manifest, work_dir).and_return(manifest_builder)
      manifest_builder.should_receive(:merge_templates)
      subject
    end
  end

  describe "#merge_templates" do
    subject { Bosh::Workspace::ManifestBuilder.new manifest, work_dir }

    before do
      File.stub(:exists?).with(/templates\//).and_return(template_exists)
    end

    context "missing template" do
      let(:template_exists) { false }
      it "raises error" do
        expect{ subject.merge_templates }.to raise_error(/does not exist/)
      end
    end

    context "template exists" do
      let(:template_exists) { true }
      let(:dir_exists) { true }

      let(:filterd_releases) { manifest.releases.tap { |rs| rs.map { |r| r.delete("git") } } }
      let(:meta_file_content) do
        {
          "name" => manifest.name,
          "director_uuid" => manifest.director_uuid,
          "stemcells" => manifest.stemcells,
          "releases" => filterd_releases,
          "meta" => manifest.meta
        }
      end

      before do
        File.stub(:exists?).with(/\.stubs/).and_return(dir_exists)
        IO.should_receive(:write).with(/\.stubs\/.+yml/, meta_file_content.to_yaml)
      end

      context "no hidden dirs" do
        let(:dir_exists) { false }
        it "creates hidden dirs" do
          subject.stub(:spiff_merge)
          Dir.should_receive(:mkdir).with(/.stubs/)
          subject.merge_templates
        end
      end

      it "generates manifest with spiff" do
        subject.should_receive(:spiff_merge) do |args|
          if args.is_a?(Array)
            expect(args.first).to match(/\/templates\/.+yml/)
            expect(args.last).to match(/\.stubs\/.+yml/)
          else
            expect(args).to match(/\.deployments\/.+yml/)
          end
        end
        subject.merge_templates
      end
    end
  end
end

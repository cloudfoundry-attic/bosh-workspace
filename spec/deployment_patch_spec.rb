module Bosh::Workspace
  describe DeploymentPatch do
    let(:stemcells) { [{ 'name' => 'foo', 'version' => 1 }] }
    let(:releases) { [{ 'name' => 'bar', 'version' => 2 }] }
    let(:templates_dir) do
      home = extracted_asset_dir("home", "foo-boshworkspace.zip")
      File.join(home, "foo-boshworkspace", "templates")
    end
    let(:templates_ref) { 'bb802816a44d0fd23fd0120f4fdd42578089d025' }
    let(:patch) { DeploymentPatch.new(stemcells, releases, templates_ref) }
    let(:patch_yaml_data) { patch_data.to_yaml }
    let(:deployment_file) { get_tmp_file_path deployment.to_yaml }
    let(:patch_data) do
      { "stemcells" => stemcells, "releases" => releases, "templates_ref" => templates_ref }
    end
    let(:deployment) do
      {
        'name' => 'foo',
        'stemcells' => stemcells,
        'releases' => releases,
        'templates' => [ 'foo/bar.yml' ],
        'meta' => { 'foo' => 'bar' }
      }
    end

    describe '#create' do
      subject { DeploymentPatch.create deployment_file, templates_dir }

      context "with templates submodule" do
        its(:stemcells) { should eq stemcells }
        its(:releases) { should eq releases }
        its(:templates_ref) { should eq templates_ref }
      end

      context "without templates submodule" do
        let(:templates_dir) do
          asset_dir("manifests-repo/templates")
        end

        it "ignores templates directory" do
          expect(subject.templates_ref).to be_nil
        end
      end
    end

    describe '.from_file' do
      subject { DeploymentPatch.from_file get_tmp_file_path(patch_yaml_data) }
      its(:stemcells) { should eq stemcells }
      its(:releases) { should eq releases }
      its(:templates_ref) { should eq templates_ref }
    end

    describe '#perform_validation' do
      context "valid" do
        it "validates" do
          allow_any_instance_of(Schemas::DeploymentPatch)
            .to receive(:validate).with(patch_data)
          expect(patch).to be_valid
        end
      end

      context "invalid" do
        it "has errors" do
          allow_any_instance_of(Schemas::DeploymentPatch)
            .to receive(:validate).with(patch_data)
            .and_raise(Membrane::SchemaValidationError.new("foo"))
          expect(patch).to_not be_valid
          expect(patch.errors).to include "foo"
        end
      end
    end

    describe '#to_hash' do
      subject { patch.to_hash }
      it { should eq patch_data }

      context "without templates_ref" do
        let(:templates_ref) { nil }
        before { patch_data.delete "templates_ref" }
        it { should eq patch_data }
      end
    end

    describe '#to_yaml' do
      subject { patch.to_yaml }
      it { should eq patch_yaml_data }
    end

    describe '#to_file' do
      let(:patch_file) { 'foo.yml' }

      it 'writes to file' do
        expect(IO).to receive(:write).with(patch_file, patch_yaml_data)
        patch.to_file(patch_file)
      end
    end

    describe '#apply' do
      let(:templates_ref) { '505b82012133673a9150d4e83aede1a07598154b' }
      let(:deployment) { { "stemcells" => [], "releases" => [] } }
      let(:deployment_new) { { "stemcells" => stemcells, "releases" => releases } }
      let(:template_files) { Dir.entries(templates_dir) }

      subject { patch.apply(deployment_file, templates_dir) }

      it 'applies changes'  do
        expect(IO).to receive(:write)
          .with(deployment_file, deployment_new.to_yaml)
        subject
        expect(template_files).to include "bar.yml"
      end

      context "without templates_ref" do
        let(:templates_ref) { nil }
        it 'leaves templates dir as is' do
          subject
          expect(template_files).to include "foo.yml"
          expect(template_files).to_not include "bar.yml"
        end
      end
    end

    describe '#changes' do
      context 'with changes' do
        let(:new_patch) do
          DeploymentPatch.new(
            [{ 'name' => 'foo', 'version' => 2 }, { 'name' => 'baz', 'version' => 1 }],
            [{ 'name' => 'qux', 'version' => 3 }],
            'e598fece364ba7447b2e897d71d7008f8390fb86'
          )
        end
        subject { patch.changes(new_patch) }

        its([:stemcells]) { should eq "changed foo 1 2, added baz 1" }
        its([:releases]) { should eq "removed bar 2, added qux 3" }
        its([:templates_ref]) { should eq "changed bb80281 e598fec" }

        context 'without templates_ref' do
          subject { patch.changes(new_patch) }
          let(:templates_ref) { nil }

          its([:stemcells]) { should eq "changed foo 1 2, added baz 1" }
          its([:releases]) { should eq "removed bar 2, added qux 3" }
          its([:templates_ref]) { should be_nil }
        end
      end

      context 'without changes' do
        subject { patch.changes(patch) }
        it { should be_a(Hash) }
        it { should be_empty }
      end
    end

    describe '#changes?' do
      context 'with changes' do
        let(:new_patch) { DeploymentPatch.new(stemcells, releases, 'foo') }
        subject { patch.changes?(new_patch) }
        it { should be true }
      end

      context 'without changes' do
        subject { patch.changes?(patch) }
        it { should be false }
      end
    end
  end
end

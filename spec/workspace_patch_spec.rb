module Bosh::Workspace
  describe WorkspacePatch do
    let(:stemcells) { [{ 'name' => 'foo', 'version' => 1 }] }
    let(:releases) { [{ 'name' => 'bar', 'version' => 2 }] }
    let(:templates_dir) do
      home = extracted_asset_dir("home", "foo-boshworkspace.zip")
      workspace = File.join(home, "foo-boshworkspace")
      Dir[File.join(workspace, ".git/**/config")].each do |c|
        IO.write(c, IO.read(c).gsub(/(\/U.+tmp)/, home))
      end
      File.join(workspace, "templates")
    end
    let(:templates_ref) { 'bb802816a44d0fd23fd0120f4fdd42578089d025' }
    let(:patch) { WorkspacePatch.new(deployments, templates_ref) }
    let(:patch_yaml_data) { patch_data.to_yaml }
    let(:deployment_files) { { 'foo' => foo_deployment_file, 'bar' => bar_deployment_file } }
    let(:foo_deployment) { deployment }
    let(:bar_deployment) { deployment.tap { |d| d['name'] = 'bar' } }
    let(:foo_deployment_file) { get_tmp_file_path foo_deployment.to_yaml }
    let(:bar_deployment_file) { get_tmp_file_path bar_deployment.to_yaml }
    let(:deployments) do
      [
        { 'name' => 'foo', 'stemcells' => stemcells, 'releases' => releases  },
        { 'name' => 'bar', 'stemcells' => stemcells, 'releases' => releases  }
      ]
    end
    let(:patch_data) do
      { 'deployments' => deployments, 'templates_ref' => templates_ref }
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
      subject { WorkspacePatch.create deployment_files, templates_dir }

      context "with templates submodule" do
        its(:deployments) { should eq deployments }
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
      subject { WorkspacePatch.from_file get_tmp_file_path(patch_yaml_data) }
      its(:deployments) { should eq deployments }
      its(:templates_ref) { should eq templates_ref }
    end

    describe '#perform_validation' do
      context "valid" do
        it "validates" do
          allow_any_instance_of(Schemas::WorkspacePatch)
            .to receive(:validate).with(patch_data)
          expect(patch).to be_valid
        end
      end

      context "invalid" do
        it "has errors" do
          allow_any_instance_of(Schemas::WorkspacePatch)
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
      let(:patch_file) { get_tmp_file_path '{}' }

      it 'writes to file' do
        patch.to_file(patch_file)
        expect(IO.read(patch_file)).to eq patch_yaml_data
      end
    end

    describe '#apply' do
      let(:templates_ref) { '505b82012133673a9150d4e83aede1a07598154b' }
      let(:foo_deployment) do
        { "stemcells" => [], "releases" => [], "name" => "foo" }
      end
      let(:bar_deployment) do
        { "stemcells" => [], "releases" => [], "name" => "bar" }
      end
      let(:new_foo_deployment) do
        { "stemcells" => stemcells, "releases" => releases, "name" => "foo" }
      end
      let(:new_bar_deployment) do
        { "stemcells" => stemcells, "releases" => releases, "name" => "bar" }
      end
      let(:template_files) { Dir.entries(templates_dir) }

      subject { patch.apply(deployment_files, templates_dir) }

      it 'applies changes' do
        subject
        expect(IO.read(foo_deployment_file)).to eq new_foo_deployment.to_yaml
        expect(IO.read(bar_deployment_file)).to eq new_bar_deployment.to_yaml
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
          WorkspacePatch.new(
            [
              {
                'name' => 'foo',
                'releases' => [
                  { 'name' => 'bar', 'version' => 3 }
                ],
                'stemcells' => [{ 'name' => 'foo', 'version' => 3 }]
              },{
                'name' => 'bar',
                'releases' => [
                  { 'name' => 'bar', 'version' => 2 },
                ],
                'stemcells' => [{ 'name' => 'qux', 'version' => 1 }]
              }
            ],
            'e598fece364ba7447b2e897d71d7008f8390fb86'
          )
        end
        subject { patch.changes(new_patch) }

        its(['deployments', 'foo']) { should match /\+ 3/ }
        its(['deployments', 'bar']) { should match /\- version/ }
        its(['templates_ref']) { should match /\+ e598fec/ }

        context 'without templates_ref' do
          subject { patch.changes(new_patch) }
          let(:templates_ref) { nil }

          its(['deployments', 'foo']) { should match /\+ 3/ }
          its(['deployments', 'bar']) { should match /\- version/ }
          its(['templates_ref']) { should be_nil }
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
        let(:new_patch) { WorkspacePatch.new(deployments, 'foo') }
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

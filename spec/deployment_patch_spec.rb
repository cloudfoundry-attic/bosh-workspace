module Bosh::Workspace
  describe DeploymentPatch do
    let(:stemcells) { [{ 'name' => 'foo', 'version' => 1 }] }
    let(:releases) { [{ 'name' => 'bar', 'version' => 2 }] }
    let(:templates_ref) { '803b66609eea575ba336417c15f8a5d030a114a0' }
    let(:templates_dir) { 'templates' }
    let(:templates_repo) { instance_double('Git::Base') }
    let(:patch) { DeploymentPatch.new(stemcells, releases, templates_ref) }
    let(:patch_yaml_data) { patch_data.to_yaml }
    let(:deployment_file) { get_tmp_file_path deployment.to_yaml }
    let(:patch_data) do
      { stemcells: stemcells, releases: releases, templates_ref: templates_ref }
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
      let(:templates_commit) { instance_double('Git::Object::Commit') }
      subject { DeploymentPatch.create deployment_file, templates_dir }

      before do
        allow(Git).to receive(:open).with(templates_dir)
          .and_return(templates_repo)
        allow(templates_repo).to receive(:log).with(1)
          .and_return([templates_commit])
        allow(templates_commit).to receive(:sha)
          .and_return(templates_ref)
      end

      its(:stemcells) { should eq stemcells }
      its(:releases) { should eq releases }
      its(:templates_ref) { should eq templates_ref }
    end

    describe '#from_file' do
      subject { DeploymentPatch.from_file get_tmp_file_path(patch_yaml_data) }
      its(:stemcells) { should eq stemcells }
      its(:releases) { should eq releases }
      its(:templates_ref) { should eq templates_ref }
    end

    describe '.to_yaml' do
      subject { patch.to_yaml }
      it { should eq patch_yaml_data }
    end

    describe '.to_file' do
      let(:patch_file) { 'foo.yml' }

      it 'writes to file' do
        expect(IO).to receive(:write).with(patch_file, patch_yaml_data)
        patch.to_file(patch_file)
      end
    end

    describe '.apply' do
      let(:deployment) { { "stemcells" => [], "releases" => [] } }
      let(:deployment_new) { { "stemcells" => stemcells, "releases" => releases } }

      before do
        allow(Git).to receive(:open).with(templates_dir)
          .and_return(templates_repo)
      end

      it 'applies changes' do
        expect(templates_repo).to receive(:checkout).with(templates_ref)
        expect(IO).to receive(:write).with(deployment_file, deployment_new.to_yaml)
        patch.apply(deployment_file, templates_dir)
      end
    end

    describe '.changes' do
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
        its([:templates_ref]) { should eq "changed 803b666 e598fec" }
      end

      context 'without changes' do
        subject { patch.changes(patch) }
        it { should be_a(Hash) }
        it { should be_empty }
      end
    end

    describe '.changes?' do
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

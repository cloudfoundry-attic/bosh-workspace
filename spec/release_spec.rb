describe Bosh::Workspace::Release do
  let(:name) { "foo"}
  let(:version) { 3 }
  let(:repo) { extracted_asset_dir("foo", "foo-boshrelease-repo.zip") }
  let(:release_data) { { "name" => name, "version" => version, "git" => repo } }
  let(:releases_dir) { File.join(asset_dir("manifests-repo"), ".releases") }
  let(:release) { Bosh::Workspace::Release.new release_data, releases_dir }
  let(:templates) { Dir[File.join(releases_dir, name, "templates/*.yml")].to_s }

  describe "#update_repo" do
    subject { Dir[File.join(releases_dir, name, "releases/foo*.yml")].to_s }

    context "latest version" do
      before {  release.update_repo }

      let(:version) { "latest" }

      it "checks out repo" do
        expect(subject).to match(/foo-11.yml/)
      end

      it "does not include templates from master" do
        expect(templates).to_not match(/deployment.yml/)
      end
    end

    context "specific version" do
      let(:version) { "11" }
      before {  release.update_repo }

      it "checks out repo" do
        expect(subject).to match(/foo-11.yml/)
      end

      it "does not include templates from master" do
        expect(templates).to_not match(/deployment.yml/)
      end
    end

    context "specific version" do
      let(:version) { "2" }

      it "checks out repo" do
        release.update_repo
        expect(subject).to match(/foo-2.yml/)
      end
    end

    context "specific ref with latest release" do
      let(:release_data) do 
        { "name" => name, "version" => "latest", "ref" => "66658", "git" => repo }
      end

      it "checks out repo" do
        release.update_repo
        expect(subject).to match(/foo-2.yml/)
        expect(subject).to_not match(/foo-3.yml/)
      end
    end

    context "updated version " do
      let(:version) { "11" }

      it "checks out file with multiple commits" do
        release.update_repo
        expect(subject).to match(/foo-11.yml/)
      end
    end

    context "non existing version " do
      let(:version) { "12" }

      it "raises an error" do
        expect { release.update_repo }.
          to raise_error(/Could not find version/)
      end
    end

    context "already cloned repo" do
      before do
        data = { "name" => name, "version" => 1, "git" => repo }
        cloned_release = Bosh::Workspace::Release.new(data, releases_dir)
        cloned_release.update_repo
      end

      it "version 3" do
        release.update_repo
        expect(subject).to match(/foo-3.yml/)
      end
    end

    context "multiple releases" do
      let(:version) { "11" }

      before do
        data = { "name" => "bar", "version" => 2, "git" => repo }
        other_release = Bosh::Workspace::Release.new(data, releases_dir)
        other_release.update_repo
      end

      it "version 3" do
        release.update_repo
        expect(subject).to match(/foo-11.yml/)
        expect(templates).to_not match(/deployment.yml/)
      end
    end
  end

  describe "attributes" do
    subject { release }
    its(:name){ should eq name }
    its(:git_uri){ should eq repo }
    its(:repo_dir){ should match(/\/#{name}$/) }
    its(:manifest_file){ should match(/\/#{name}-#{version}.yml$/) }
    its(:manifest){ should match "releases/#{name}-#{version}.yml$" }
    its(:name_version){ should eq "#{name}/#{version}" }
    its(:version){ should eq version }
  end

  after do
    FileUtils.rm_r releases_dir
  end
end

describe Bosh::Workspace::ReleaseManager do
  let(:releases) { [ release_data ] }
  let(:release_data)  { { "name" => "foo" } }
  let(:work_dir) { asset_dir("manifests-repo") }
  let(:releases_dir) { File.join(work_dir, ".releases") }
  let(:release) { instance_double("Bosh::Workspace::Release") }
  subject { Bosh::Workspace::ReleaseManager.new(releases, work_dir) }

  describe "#update_release_repos" do
    it "invokes checkout_current_version" do
      Bosh::Workspace::Release.should_receive(:new)
        .with(release_data, releases_dir).and_return(release)
      release.should_receive(:checkout_current_version)
      subject.update_release_repos
    end
  end
end

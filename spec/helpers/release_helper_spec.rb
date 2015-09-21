module Bosh::Workspace
  describe ReleaseHelper do
    class ReleaseHelperTester
      include ReleaseHelper

      attr_reader :director, :work_dir

      def initialize(director, work_dir)
        @director = director
        @work_dir = work_dir
      end
    end

    subject { release_helper }
    let(:release_helper) { ReleaseHelperTester.new(director, work_dir) }
    let(:director) { instance_double('Bosh::Cli::Client::Director') }
    let(:work_dir) { asset_dir("manifests-repo") }

    describe "#release_upload" do
      let(:release_cmd) do
        instance_double "Bosh::Cli::Command::Release::UploadRelease"
      end

      before do
        allow(Bosh::Cli::Command::Release::UploadRelease).to receive(:new)
          .and_return(release_cmd)
      end

      let(:manifest_file) { "foo-1.yml." }
      subject { release_helper.release_upload(manifest_file, work_dir) }

      it "uploads release" do
        expect(release_cmd).to receive(:upload).with(manifest_file)
        subject
      end
    end

    describe "#release_uploaded?" do
      let(:releases) { { "versions" => %w(1 2 3) } }
      subject { release_helper.release_uploaded?("foo", version) }
      before do
        expect(director).to receive(:get_release)
          .with("foo").and_return(releases)
      end

      context "release exists" do
        let(:version) { 2 }
        it { should be true }
      end

      context "release not found" do
        let(:version) { "8" }
        it { should be false }
      end
    end

    describe "#release_dir" do
      let(:releases_dir) { File.join(work_dir, ".releases") }
      subject { release_helper.releases_dir }

      before do
        expect(FileUtils).to receive(:mkdir_p).once
          .with(releases_dir).and_return([releases_dir])
      end

      it { should eq releases_dir }

      it "memoizes" do
        subject
        expect(subject).to eq releases_dir
      end
    end

    describe "#project_deployment_releases" do
      subject { release_helper.project_deployment_releases }
      let(:release) { instance_double("Bosh::Workspace::Release") }
      let(:release_data) { { name: "foo" } }
      let(:releases) { [release_data, release_data] }
      let(:options) { { offline: offline } }
      let(:offline) { nil }
      let(:credentials_provider) do
        instance_double('Bosh::Workspace::GitCredentialsProvider',
                        callback: :callback)
      end

      before do
        expect(release_helper)
          .to receive_message_chain("project_deployment.releases")
          .and_return(releases)
        expect(GitCredentialsProvider).to receive(:new).with(/.credentials.yml/)
          .and_return(credentials_provider)
      end

      it "inits releases" do
        expect(Release).to receive(:new).twice
          .with(release_data, /\/.releases/, :callback, options)
          .and_return(release)
        expect(subject).to eq [release, release]
      end

      context "when offline" do
        before { release_helper.offline! }
        let(:offline) { true }

        it "inits releases" do
          expect(Release).to receive(:new).twice
            .with(release_data, /\/.releases/, :callback, options)
            .and_return(release)
          expect(subject).to eq [release, release]
        end
      end
    end
  end
end

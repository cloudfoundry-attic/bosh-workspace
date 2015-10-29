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

    def expect_option(subject, *args)
      expect(subject).to receive(:add_option).with(*args)
    end

    context "with upload release command" do
      let(:upload_release_cmd) do
        instance_double "Bosh::Cli::Command::Release::UploadRelease"
      end

      before do
        allow(Bosh::Cli::Command::Release::UploadRelease)
          .to receive(:new).and_return(upload_release_cmd)
      end

      describe "#release_upload_from_url" do
        let(:url) { "http://example.com/release.tgz" }
        subject { release_helper.release_upload_from_url(url) }

        it "uploads release" do
          expect(upload_release_cmd).to receive(:upload).with(url)
          subject
        end
      end

      describe "#release_upload" do
        let(:manifest) { "foo-1.yml" }
        let(:tarball) { "foo-1.tgz" }
        let(:release_dir) { "foo-release" }
        let(:exist) { true }
        let(:create_release_cmd) do
          instance_double("Bosh::Cli::Command::Release::CreateRelease")
        end

        subject { release_helper.release_upload(manifest, release_dir) }

        before do
          allow(Bosh::Cli::Command::Release::CreateRelease)
            .to receive(:new).and_return(create_release_cmd)
          allow(File).to receive(:exist?).with(tarball).and_return(exist)
        end

        context "when offline" do
          before { release_helper.offline! }

          context "with final release tarball" do
            it "uploads final release" do
              expect(upload_release_cmd).to receive(:upload).with(tarball)
              subject
            end
          end

          context "without final release tarball" do
            let(:exist) { false }
            it "raises an error" do
              expect{subject}.to raise_error /tarball missing.+#{tarball}/
            end
          end
        end

        context "when online" do
          context "with final release tarball" do
            it "uploads final release" do
              expect(upload_release_cmd).to receive(:upload).with(tarball)
              subject
            end
          end

          context "without final release tarball" do
            let(:exist) { false }
            it "creates and uploads final release" do
              expect_option(create_release_cmd, :with_tarball, true)
              expect_option(create_release_cmd, :dir, release_dir)
              expect(create_release_cmd).to receive(:create).with(manifest)
              expect(upload_release_cmd).to receive(:upload).with(tarball)
              subject
            end
          end
        end
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

require "bosh/cli/commands/prepare"

describe Bosh::Cli::Command::Prepare do
  describe "#prepare" do
    let(:command) { Bosh::Cli::Command::Prepare.new }
    let(:url) { nil }
    let(:release) do
      instance_double("Bosh::Workspace::Release",
        name: "foo", version: "1", repo_dir: ".releases/foo", git_url: "/.git",
        release_dir: '.releases/foo/sub', name_version: "foo/1", url: url,
        manifest_file: "releases/foo-1.yml")
    end
    let(:stemcell) do
      instance_double("Bosh::Workspace::Stemcell",
        name: "bar", version: "2", name_version: "bar/2",
        file: ".stemcesll/bar-2.tgz", file_name: "bar-2.tgz")
    end

    before do
      allow(command).to receive(:rquire_project_deployment)
      allow(command).to receive(:auth_required)
      allow(command).to receive(:project_deployment_releases)
        .and_return(releases)
      allow(command).to receive(:project_deployment_stemcells)
        .and_return(stemcells)
    end

    describe "prepare_release(s/_repos)" do
      let(:releases) { [release] }
      let(:subrepos) { [] }
      let(:stemcells) { [] }
      let(:ref) { nil }

      context "when only performing local operations" do
        before { command.add_option(:local, true) }
        let(:releases) { [] }

        it "enables offline mode" do
          expect(command).to receive(:offline!)
          command.prepare
        end
      end

      context "release with git " do
        before do
          expect(release).to receive(:update_repo)
          expect(release).to receive(:ref).and_return(ref)
          expect(command).to receive(:release_uploaded?)
            .with(release.name, release.version).and_return(release_uploaded)
        end

        context "release uploaded" do
          let(:release_uploaded) { true }

          it "does not upload the release" do
            expect(command).to_not receive(:release_upload)
            command.prepare
          end
        end

        context "release not uploaded with ref" do
          let(:release_uploaded) { false }
          let(:ref) { "0f910f" }

          context "without release ref" do
            it "does upload the release" do
              expect(release).to receive(:ref).and_return(ref)
              expect(command).to receive(:release_upload)
                .with(release.manifest_file, release.release_dir)
              command.prepare
            end
          end
        end

        context "release not uploaded with url" do
          let(:release_uploaded) { false }
          let(:url) { "bosh.io/foo/bar.tgz" }

          it "does uploads a remote release" do
            expect(command).to receive(:release_upload_from_url)
              .with(release.url)
            command.prepare
          end
        end
      end

      context "if the release git_url is not given" do
        let(:release_uploaded) { false }
        let(:release) do
          instance_double("Bosh::Workspace::Release",
            name: "foo", version: "1", repo_dir: ".releases/foo", git_url: nil,
            name_version: "foo/1", manifest_file: "releases/foo-1.yml")
        end

        it "notifies the user that the git property must be specified" do
          expect{ command.prepare }.to raise_error(/`git:' is missing from `release:/)
        end
      end
    end

    describe "prepare_stemcells" do
      let(:releases) { [] }
      let(:stemcells) { [ stemcell ] }

      before do
        expect(command).to receive(:stemcell_uploaded?)
        .with(stemcell.name, stemcell.version).and_return(stemcell_uploaded)
      end

      context "stemcell uploaded" do
        let(:stemcell_uploaded) { true }

        it "does not upload the stemcell" do
          expect(command).to_not receive(:stemcell_download)
          expect(command).to_not receive(:stemcell_upload)
          command.prepare
        end
      end

      context "stemcell not uploaded" do
        let(:stemcell_uploaded) { false }

        before do
          allow(stemcell).to receive(:downloaded?)
          .and_return(stemcell_downloaded)
        end

        context "stemcell downloaded" do
          let(:stemcell_downloaded) { true }

          it "uploads the already downloaded stemcell" do
            expect(command).to_not receive(:stemcell_download)
            expect(command).to receive(:stemcell_upload_url).with("https://bosh.io/d/stemcells/#{stemcell.name}?v=#{stemcell.version}")
            command.prepare
          end
        end

        context "when stemcell not downloaded" do
          let(:stemcell_downloaded) { false }

          it "downloads and uploads the stemcell" do
            expect(command).to receive(:stemcell_upload_url).with("https://bosh.io/d/stemcells/#{stemcell.name}?v=#{stemcell.version}")
            command.prepare
          end

        end
      end
    end
  end
end

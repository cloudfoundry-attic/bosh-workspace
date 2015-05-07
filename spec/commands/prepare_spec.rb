require "bosh/cli/commands/prepare"

describe Bosh::Cli::Command::Prepare do
  describe "#prepare" do
    let(:command) { Bosh::Cli::Command::Prepare.new }
    let(:release) do
      instance_double("Bosh::Workspace::Release",
        name: "foo", version: "1", repo_dir: ".releases/foo", git_url: "/.git",
        name_version: "foo/1", manifest_file: "releases/foo-1.yml")
    end
    let(:stemcell) do
      instance_double("Bosh::Workspace::Stemcell",
        name: "bar", version: "2", name_version: "bar/2",
        file: ".stemcesll/bar-2.tgz", file_name: "bar-2.tgz")
    end

    before do
      allow(command).to receive(:require_project_deployment)
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

      context "release with git " do
        before do
          allow(release).to receive(:required_submodules).and_return(subrepos)

          expect(release).to receive(:update_repo)
          expect(release).to_not receive(:update_submodule)
          expect(release).to receive(:ref).and_return(ref)
          expect(command).to receive(:release_uploaded?)
          .with(release.name, release.version).and_return(release_uploaded)
          expect(command).to receive(:fetch_or_clone_repo)
          .with(release.repo_dir, release.git_url)
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
                .with(release.manifest_file, release.repo_dir)
              command.prepare
            end
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

          it "does not upload the stemcell" do
            expect(command).to_not receive(:stemcell_download)
            expect(command).to receive(:stemcell_upload).with(stemcell.file)
            command.prepare
          end
        end

        context "stemcell downloaded" do
          let(:stemcell_downloaded) { false }

          it "does not upload the stemcell" do
            expect(command).to receive(:stemcell_download).with(stemcell.file_name)
            expect(command).to receive(:stemcell_upload).with(stemcell.file)
            command.prepare
          end
        end
      end
    end
  end
end

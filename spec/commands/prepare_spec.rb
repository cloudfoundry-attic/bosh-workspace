require "bosh/cli/commands/prepare"

describe Bosh::Cli::Command::Prepare do
  describe "#prepare" do
    let(:command) { Bosh::Cli::Command::Prepare.new }
    let(:release) do
      instance_double("Bosh::Workspace::Release",
        name: "foo", version: "1", repo_dir: ".releases/foo",
        name_version: "foo/1", manifest_file: "releases/foo-1.yml")
    end
    let(:stemcell) do
      instance_double("Bosh::Workspace::Stemcell",
        name: "bar", version: "2", name_version: "bar/2",
        file: ".stemcesll/bar-2.tgz", file_name: "bar-2.tgz")
    end

    before do
      command.stub(:require_project_deployment)
      command.stub(:auth_required)
      command.stub(:project_deployment_releases).and_return(releases)
      command.stub(:project_deployment_stemcells).and_return(stemcells)
    end

    describe "prepare_release(s/_repos)" do
      let(:releases) { [ release ] }
      let(:stemcells) { [] }

      before do
        release.should_receive(:update_repo) 
        command.should_receive(:release_uploaded?)
          .with(release.name, release.version).and_return(release_uploaded)
      end

      context "release uploaded" do
        let(:release_uploaded) { true }

        it "does not upload the release" do
          command.should_not_receive(:release_upload)
          command.prepare
        end
      end

      context "release not uploaded" do
        let(:release_uploaded) { false }

        it "does not upload the release" do
          command.should_receive(:release_upload).with(release.manifest_file)
          command.prepare
        end
      end
    end

    describe "prepare_stemcells" do
      let(:releases) { [] }
      let(:stemcells) { [ stemcell ] }

      before do
        command.should_receive(:stemcell_uploaded?)
          .with(stemcell.name, stemcell.version).and_return(stemcell_uploaded)
      end

      context "stemcell uploaded" do
        let(:stemcell_uploaded) { true }
      
        it "does not upload the stemcell" do
          command.should_not_receive(:stemcell_download)
          command.should_not_receive(:stemcell_upload)
          command.prepare
        end
      end

      context "stemcell not uploaded" do
        let(:stemcell_uploaded) { false }

        before { stemcell.should_receive(:downloaded?).and_return(stemcell_downloaded) }

        context "stemcell downloaded" do
          let(:stemcell_downloaded) { true }

          it "does not upload the stemcell" do
            command.should_not_receive(:stemcell_download)
            command.should_receive(:stemcell_upload).with(stemcell.file)
            command.prepare
          end
        end

        context "stemcell downloaded" do
          let(:stemcell_downloaded) { false }

          it "does not upload the stemcell" do
            command.should_receive(:stemcell_download).with(stemcell.file_name)
            command.should_receive(:stemcell_upload).with(stemcell.file)
            command.prepare
          end
        end
      end
    end
  end
end

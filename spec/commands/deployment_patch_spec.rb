require "bosh/cli/commands/deployment_patch"

module Bosh::Cli::Command
  include Bosh::Workspace

  describe DeploymentPatch do
    let(:command) { DeploymentPatch.new }
    let(:patch) { instance_double 'Bosh::Workspace::DeploymentPatch' }
    let(:current_patch) { instance_double 'Bosh::Workspace::DeploymentPatch' }
    let(:deployment_file) { 'deployments/foo.yml' }
    let(:patch_file) { 'patch.yml' }
    let(:project_dir) { File.realpath Dir.mktmpdir }
    let(:changes?) { nil }
    let(:valid?) { true }
    let(:changes) do
      { stemcells: "foo", releases: "bar", templates_ref: "baz" }
    end

    before do
      Dir.chdir project_dir
      allow(Bosh::Workspace::DeploymentPatch).to receive(:create)
        .with(deployment_file, /templates/).and_return(current_patch)
      allow(Bosh::Workspace::DeploymentPatch).to receive(:from_file)
        .with(patch_file).and_return(patch)
      allow(current_patch).to receive(:changes?).with(patch)
        .and_return(changes?)
      expect(command).to receive(:require_project_deployment)
      allow(command).to receive_message_chain("project_deployment.file")
        .and_return(deployment_file)
    end

    describe '.create' do
      it 'writes to file' do
        expect(current_patch).to receive(:to_file).with(patch_file)
        expect(command).to receive(:say).with /wrote patch/i
        command.create(patch_file)
      end
    end

    describe '.apply' do
      let(:patch_valid?) { true }

      before do
        expect(patch).to receive(:valid?).and_return(patch_valid?)
      end

      context 'with non valid patch' do
        let(:patch_valid?) { false }

        it "raises an error" do
          expect(patch).to receive(:errors).and_return(['foo', 'bar'])
          expect(command).to receive(:say).with(/validation errors/i)
          expect(command).to receive(:say).with(/foo/)
          expect(command).to receive(:say).with(/bar/)
          expect { command.apply(patch_file) }.to raise_error(/is not valid/)
        end
      end

      context 'with changes' do
        let(:changes?) { true }
        let(:index) do
          instance_double('Rugged::Index',
            read_tree: true, write_tree: true, add_all: true)
        end
        let(:repo) { instance_double 'Rugged::Repository', index: index }

        def expect_patch_changes_table
          expect(command).to receive(:say) do |s|
            subject = s.to_s.delete ' '
            expect(subject).to include "stemcells|foo"
            expect(subject).to include "releases|bar"
            expect(subject).to include "templates_ref|baz"
          end
        end

        before do
          allow(repo).to receive_message_chain('head.target.tree')
          expect(current_patch).to receive(:changes).with(patch)
            .and_return(changes)
        end

        context 'no dry-run' do
          before do
            expect(patch).to receive(:apply).with(deployment_file, /templates/)
            expect(command).to receive(:say).with /successfully applied/i
            expect_patch_changes_table
          end

          context 'without no-commit' do
            it 'applies changes, shows changes and commits' do
              expect(Rugged::Repository).to receive(:new)
                .with(project_dir).and_return(repo)
              expect(Rugged::Commit).to receive(:create) do |repo, options|
                expect(options[:message])
                  .to eq "Applied stemcells foo, releases bar, templates_ref baz"
              end
              command.apply(patch_file)
            end
          end

          context 'no-commit' do
            it 'applies changes and shows changes' do
              command.add_option(:no_commit, true)
              command.apply(patch_file)
            end
          end
        end

        context 'dry-run' do
          it 'only shows changes' do
            expect(command).to receive(:say).with /deployment patch/i
            expect_patch_changes_table
            command.add_option(:dry_run, true)
            command.apply(patch_file)
          end
        end
      end

      context 'without changes' do
        let(:changes?) { false }

        it 'says no changes' do
          expect(command).to receive(:say).with /no changes/i
          command.apply(patch_file)
        end
      end
    end
  end
end

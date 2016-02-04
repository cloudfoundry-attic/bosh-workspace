require "fileutils"

module Bosh::Workspace
  describe Release do
    let(:name) { "foo" }
    let(:release) { load_release(release_data) }
    let(:version) { "3" }
    let(:url) { "http://local.url/release" }
    let(:release_data) { { "name" => name, "version" => version, "git" => repo } }
    let(:releases_dir) { File.join(asset_dir("manifests-repo"), ".releases") }
    let(:templates) { Dir[File.join(releases_dir, name, "templates/*.yml")].to_s }
    let(:callback) { proc {} }

    def load_release(release_data, options = {}, skip_update = false)
      Release.new(release_data, releases_dir, callback, options).tap do |r|
        r.update_repo(options) unless skip_update
      end
    end

    context "with new structure within 'releases' folder" do
      let(:repo) { extracted_asset_dir("foo", "foo-boshrelease-repo-new-structure.zip") }

      describe "#update_repo" do
        subject do
          Dir[File.join(releases_dir, name, "releases/**/foo*.yml")].to_s
        end

        context "latest version" do
          before { release.update_repo }

          let(:version) { "latest" }

          it "checks out repo" do
            expect(subject).to match(/releases\/foo\/foo-12.yml/)
          end
        end

        context "version from before new structure" do
          before { release.update_repo }

          let(:version) { "11" }

          it "checks out repo" do
            expect(subject).to match(/releases\/foo-11.yml/)
          end
        end
      end

      describe "attributes" do
        let(:release_data) { { "name" => name, "version" => version, "git" => repo } }
        let(:version) { "12" }

        subject { release }

        its(:name) { should eq name }
        its(:git_url) { should eq repo }
        its(:repo_dir) { should match(/\/#{name}$/) }
        its(:release_dir) { should match(/\/#{name}$/) }
        its(:manifest) { should match "releases/#{name}/#{name}-#{version}.yml$" }
        its(:name_version) { should eq "#{name}/#{version}" }
        its(:version) { should eq version }
        its(:manifest_file) do
          should match(/\/releases\/#{name}\/#{name}-#{version}.yml$/)
        end

        context ", using a local url" do
          context "with a version placeholder" do
            let(:url) { "http://local.url/release?^VERSION^" }
            let(:version) { "12" }
            let(:release_data) { { "name" => name, "version" => version, "url" => url } }

            it 'replaces the version placeholder with the version number' do
              expect(release.url).to eq "http://local.url/release?12"
            end
          end

          context 'with no version placeholder' do
            let(:url) { "http://local.url/release" }
            let(:version) { "12" }
            let(:release_data) {{ "name" => name, "version" => version, "url" => url }}

            it 'returns the same url' do
              expect(release.url).to eq "http://local.url/release"
            end
          end
        end
      end
    end

    context "given a release with index + release v1 last touched on the same commit" do
      let(:repo) { extracted_asset_dir("foo-bar", "foo-bar-boshrelease-repo.zip") }
      let(:name) { "foo-bar" }

      before do
        FileUtils.rm_rf(releases_dir)
      end

      describe "#update_repo" do
        subject do
          Dir[File.join(releases_dir, name, "releases/foo-bar/foo-bar*.yml")].to_s
        end

        context "latest version" do
          before { release.update_repo }
          let(:version) { "latest" }
          it "checks out repo" do
            expect(subject).to match(/releases\/foo-bar\/foo-bar-2.yml/)
          end
        end
      end

      describe "attributes" do
        let(:version) { "1" }
        subject { release }
        its(:name) { should eq name}
        its(:git_url) { should eq repo }
        its(:repo_dir) { should match(/\/#{name}$/) }
        its(:manifest) { should match "releases/#{name}/#{name}-#{version}.yml$" }
        its(:name_version) { should eq "#{name}/#{version}" }
        its(:version) { should eq version }
        its(:manifest_file) do
          should match(/\/releases\/#{name}\/#{name}-#{version}.yml$/)
        end
      end
    end

    context "given a release with submodule templates" do
      let(:repo) { extracted_asset_dir("supermodule", "supermodule-boshrelease-repo.zip") }
      let(:subrepo) { extracted_asset_dir("submodule-boshrelease", "submodule-boshrelease-repo.zip") }
      let(:name) { "supermodule" }
      let(:version) { "2" }

      before do
        FileUtils.rm_rf(releases_dir)
        allow_any_instance_of(Rugged::Submodule).to receive(:url).and_return(subrepo)
      end

      describe "#update_repo" do
        subject { Rugged::Repository.new(File.join(releases_dir, name)) }

        context "with templates in submodules" do
          before do
            release = load_release("name" => name, "version" => 1, "git" => repo)
          end

          it "clones + checks out required submodules" do
            expect(subject.submodules["src/submodule"].workdir_oid)
              .to eq "2244c436777f7c305fb81a8a6e29079c92a2ab9d"
          end

          it "doesn't clone/checkout extraneous submodules" do
            expect(subject.submodules["src/other"].workdir_oid).to eq nil
          end
        end

        context "with templates in submodules" do
          before { load_release(release_data) }

          it "clones + checks out required submodules" do
            expect(subject.submodules["src/submodule"].workdir_oid)
              .to eq "95eed8c967af969d659a766b0551a75a729a7b65"
          end
          it "doesn't clone/checkout extraneous submodules" do
            expect(subject.submodules["src/other"].workdir_oid).to eq nil
          end
        end

        context "from v1 to v2" do
          let(:version) { 1 }
          before { load_release(release_data) }

          it "updates the submodules appropriately" do
            expect(subject.submodules["src/submodule"].workdir_oid)
              .to eq "2244c436777f7c305fb81a8a6e29079c92a2ab9d"
            expect(subject.submodules["src/other"].workdir_oid).to eq nil

            # Now move to v2 on existing repo
            release = load_release("name" => name, "version" => 2, "git" => repo)
            release.update_repo
            expect(subject.submodules["src/submodule"].workdir_oid)
              .to eq "95eed8c967af969d659a766b0551a75a729a7b65"
            expect(subject.submodules["src/other"].workdir_oid).to eq nil
          end
        end

        context "while being offline" do
          subject { load_release(release_data, offline: true) }

          it 'fails when repo does not yet exist' do
            expect{ subject }.to raise_error /not allowed in offline mode/
          end

          context "with an already cloned release" do
            before { load_release(release_data) }

            it 'validates local data exists' do
              expect{ subject }.to_not raise_error
            end

            context "when using latest version" do
              let(:version) { "latest" }
              subject { load_release(release_data, { offline: true }, true) }
              it 'warns when using latest while offline' do
                expect(subject).to receive(:warning).with(/using 'latest' local/i)
                subject.update_repo
              end
            end
          end
        end
      end
    end

    context "given a release that has the whole templates/ dir symlinked from a submodule" do
      let(:repo) { extracted_asset_dir("supermodule-all-templates-symlinked", "supermodule-all-templates-symlinked-boshrelease-repo.zip") }
      let(:subrepo) { extracted_asset_dir("submodule-boshrelease", "submodule-boshrelease-repo.zip") }
      let(:name) { "supermodule-all-templates-symlinked" }
      let(:version) { "1" }

      before do
        FileUtils.rm_rf(releases_dir)
        allow_any_instance_of(Rugged::Submodule).to receive(:url).and_return(subrepo)
      end

      describe "#update_repo" do
        subject { Rugged::Repository.new(File.join(releases_dir, name)) }

        context "with templates in submodules" do
          before do
            release = load_release("name" => name, "version" => 1, "git" => repo)
          end

          it "clones + checks out required submodules" do
            expect(subject.submodules["src/submodule"].workdir_oid)
                .to eq "95eed8c967af969d659a766b0551a75a729a7b65"
          end

          it "doesn't clone/checkout extraneous submodules" do
            expect(subject.submodules["src/other"].workdir_oid).to eq nil
          end
        end
      end
    end

    context "given a release with deprecated structure within 'releases' folder" do
      let(:repo) { extracted_asset_dir("foo", "foo-boshrelease-repo.zip") }

      describe "#update_repo" do
        subject { Dir[File.join(releases_dir, name, "releases/foo*.yml")].to_s }

        context "latest version" do
          before { release.update_repo }

          let(:version) { "latest" }

          it "checks out repo" do
            expect(subject).to match(/foo-12.yml/)
          end

          it "does not include templates from master" do
            expect(templates).to_not match(/deployment.yml/)
          end
        end

        context "specific version" do
          let(:version) { "12" }
          before { release.update_repo }

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
            {"name" => name, "version" => "latest", "ref" => "66658", "git" => repo}
          end

          it "checks out repo" do
            release.update_repo
            expect(subject).to match(/foo-2.yml/)
            expect(subject).to_not match(/foo-3.yml/)
          end
        end

        context "specific ref from different branch with specific release" do
          let(:release_data) do
            {"name" => name, "version" => "9.1", "ref" => "9c899", "git" => repo}
          end

          it "checks out repo" do
            release.update_repo
            expect(subject).to match(/foo-9.1.yml/)
          end
        end

        context "specific ref from different branch with latest release" do
          let(:release_data) do
            {"name" => name, "version" => "latest", "ref" => "9c899", "git" => repo}
          end

          it "checks out repo" do
            release.update_repo
            expect(subject).to match(/foo-9.2.yml/)
            expect(subject).to_not match(/foo-10.yml/)
          end
        end

        context "updated version" do
          let(:version) { "11" }

          it "checks out file with multiple commits" do
            release.update_repo
            expect(subject).to match(/foo-11.yml/)
          end
        end

        context "non existing version " do
          let(:version) { "13" }

          it "raises an error" do
            expect { release.update_repo }
              .to raise_error(/Could not find version/)
          end
        end

        context "already cloned repo" do
          before do
            load_release("name" => name, "version" => 1, "git" => repo).update_repo
          end

          it "version 3" do
            release.update_repo
            expect(subject).to match(/foo-3.yml/)
          end
        end

        context "multiple releases" do
          let(:version) { "11" }

          before do
            load_release("name" => "foo", "version" => 2, "git" => repo).update_repo
          end

          it "version 11" do
            release.update_repo
            expect(subject).to match(/foo-11.yml/)
            expect(templates).to_not match(/deployment.yml/)
          end
        end

        context "specific version" do
          let(:version) { "11" }
          before { release.update_repo }

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
            {"name" => name, "version" => "latest", "ref" => "66658", "git" => repo}
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
          let(:version) { "13" }

          it "raises an error" do
            expect { release.version }.
              to raise_error(/Could not find version/)
          end
        end

        context "already cloned repo" do
          before do
            load_release("name" => name, "version" => 1, "git" => repo).update_repo
          end

          it "version 3" do
            release.update_repo
            expect(subject).to match(/foo-3.yml/)
          end
        end

        context "multiple releases" do
          let(:version) { "11" }

          before do
            load_release("name" => "foo", "version" => 2, "git" => repo).update_repo
          end

          it "version 11" do
            release.update_repo
            expect(subject).to match(/foo-11.yml/)
            expect(templates).to_not match(/deployment.yml/)
          end
        end

        context "new release in already cloned repo" do
          let(:version) { "12" }

          before do
            load_release("name" => name, "version" => 1, "git" => repo).update_repo
            extracted_asset_dir("foo", "foo-boshrelease-repo-updated.zip")
          end

          it "version 12" do
            release.update_repo
            expect(subject).to match(/foo-12.yml/)
          end
        end
      end

      describe "attributes" do
        subject { release }
        its(:name) { should eq name }
        its(:git_url) { should eq repo }
        its(:repo_dir) { should match(/\/#{name}$/) }
        its(:release_dir) { should match(/\/#{name}$/) }
        its(:manifest_file) { should match(/\/#{name}-#{version}.yml$/) }
        its(:manifest) { should match "releases/#{name}-#{version}.yml$" }
        its(:name_version) { should eq "#{name}/#{version}" }
        its(:version) { should eq version.to_s }
      end
    end

    context "given a release which is located in a subfolder" do
      let(:repo) { extracted_asset_dir("foo", "foo-boshrelease-repo-subdir.zip") }
      let(:release_data) do
        { "name" => name, "version" => version, "git" => repo, "path" => "release"  }
      end

      describe "#update_repo" do
        subject do
          Dir[File.join(releases_dir, name, "release/releases/**/*.yml")].to_s
        end

        context "latest version" do
          before { release.update_repo }

          let(:version) { "latest" }

          it "checks out repo" do
            expect(subject).to match(/release\/releases\/foo-12.yml/)
          end
        end
      end

      describe "attributes" do
        let(:version) { "12" }
        subject { release }
        its(:name) { should eq name }
        its(:git_url) { should eq repo }
        its(:repo_dir) { should match(/\/#{name}$/) }
        its(:release_dir) { should match(/\/#{name}\/release$/) }
        its(:manifest) { should match "release/releases/#{name}-#{version}.yml$" }
        its(:name_version) { should eq "#{name}/#{version}" }
        its(:version) { should eq version }
        its(:manifest_file) do
          should match(/\/release\/releases\/#{name}-#{version}.yml$/)
        end
      end
    end

    context "correct checkout behavior:" do
      let(:release_data) { { "name" => name, "version" => version,
                             "git" => repo, "ref" => :fooref } }
      let(:repo) { 'foo/bar' }
      let(:repository) do
        instance_double('Rugged::Repository', lookup: double(oid: :fooref))
      end

      describe "#update_repo_with_ref" do
        subject do
          Release.new(release_data, releases_dir, callback)
        end

        before do
          expect(Rugged::Repository).to receive(:new)
            .and_return(repository).at_least(:once)
          expect(repository).to receive(:fetch)
          expect(repository).to receive(:references) do
            { 'refs/remotes/origin/HEAD' =>
              double(resolve: double(target_id: :oid)) }
          end
          allow(subject).to receive(:repo_exists?).and_return(true)
        end

        it "calls checkout_tree and checkout" do
          expect(repository).to receive("checkout_tree").at_least(:once)
          expect(repository).to receive("checkout").at_least(:once)
          subject.update_repo
        end
      end
    end

    context "given a release which moved a directory to a symlink across versions" do
      let(:repo) do
        extracted_asset_dir("symlinkreplacement", "symlinkreplacement-boshrelease-repo.zip")
      end
      let(:name) { "symlinkreplacement" }

      describe "#update_repo" do
        subject { Rugged::Repository.new(File.join(releases_dir, name)) }
        context "using a previous version should work" do
          before do
            FileUtils.rm_rf(releases_dir)

            release = load_release("name" => name, "version" => "1", "git" => repo)
            release.update_repo
          end
          it "git state is happy" do
            expect(subject.head.target.oid).to eq "d96521d1940934b1941e0f4a462d3a5e9f31c75d"
            expect(subject.diff_workdir(subject.head.target.oid).size).to eq 0
          end
        end
      end
    end
  end
end

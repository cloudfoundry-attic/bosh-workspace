describe Bosh::Workspace::Release do
  include Bosh::Workspace::GitCredentialsHelper
  let(:name) { "foo" }
  let(:release) { load_release(release_data) }
  let(:version) { "3" }
  let(:release_data) { { "name" => name, "version" => version, "git" => repo } }
  let(:releases_dir) { File.join(asset_dir("manifests-repo"), ".releases") }
  let(:templates) { Dir[File.join(releases_dir, name, "templates/*.yml")].to_s }

  def load_release(release_data)
    Bosh::Workspace::Release.new(release_data, releases_dir).tap do |r|
      fetch_or_clone_repo(r.repo_dir, repo)
    end
  end

  context "given a release with new structure within 'releases' folder" do
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
      let(:version) { "12" }
      subject { release }
      its(:name) { should eq name }
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

    describe "#update_repo" do
      subject { Rugged::Repository.new(File.join(releases_dir, name)) }
      context "with templates in submodules" do
        before do
          system("rm -rf #{releases_dir}")
          allow_any_instance_of(Rugged::Submodule).to receive(:url).and_return(subrepo)

          load_release("name" => name, "version" => 1, "git" => repo).update_repo
        end

        it "clones + checks out required submodules" do
          expect(subject.submodules["src/submodule"].workdir_oid)
            .to eq subject.submodules["src/submodule"].index_oid
        end
        it "doesn't clone/checkout extraneous submodules" do
          expect(subject.submodules["src/other"].workdir_oid).to eq nil
        end
      end
      context "with templates in submodules" do
        before do
          system("rm -rf #{releases_dir}")
          allow_any_instance_of(Rugged::Submodule).to receive(:url).and_return(subrepo)

          load_release("name" => name, "version" => 2, "git" => repo).update_repo
        end

        it "clones + checks out required submodules" do
          expect(subject.submodules["src/submodule"].workdir_oid)
            .to eq subject.submodules["src/submodule"].index_oid
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
          expect(subject).to match(/foo-11.yml/)
        end

        it "does not include templates from master" do
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

      context "updated version" do
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
        let(:version) { "12" }

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
      its(:manifest) { should match "release/releases/#{name}-#{version}.yml$" }
      its(:name_version) { should eq "#{name}/#{version}" }
      its(:version) { should eq version }
      its(:manifest_file) do
        should match(/\/release\/releases\/#{name}-#{version}.yml$/)
      end
    end
  end
end

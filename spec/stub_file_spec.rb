describe Bosh::Workspace::StubFile do
  let(:project_deployment) { instance_double("Bosh::Workspace::ProjectDeployment",
    name: "bar",
    director_uuid: "foo-bar-uuid",
    stemcells: stemcells,
    releases: [ { "name" => "foo", "version" => "latest", "git" => "release_repo.git" } ],
    templates: ["foo.yml"],
    meta: meta,
    merged_file: ".deployments/foo.yml")
  }
  let(:meta) {{ "foo" => "bar" }}
  let(:stemcells) { [ { "name" => "foo", "version" => "2"} ] }
  let(:path) { "foo/.stubs/bar.yml"}

  let(:stub_file) { Bosh::Workspace::StubFile.new(project_deployment) }
  subject { stub_file }

  describe ".create" do
    let(:stub_file) { instance_double("Bosh::Workspace::StubFile") }
    subject { Bosh::Workspace::StubFile.create(path, project_deployment) }

    it "calls write" do
      Bosh::Workspace::StubFile.should_receive(:new)
        .with(project_deployment).and_return(stub_file)
      stub_file.should_receive(:write).with(path)
      subject
    end
  end

  describe "#write" do
    it "writes yaml content" do
      IO.should_receive(:write).with(path, /---\n/)
      subject.write(path)
    end
  end

  describe "#content" do
    subject { stub_file.content }
    its(["name"]) { should eq project_deployment.name }
    its(["director_uuid"]) { should eq project_deployment.director_uuid }
    its(["releases"]) { should be_a(Array) }
    its(["meta"]) { should be_a(Hash) }
  end

  describe "#releases" do
    it "filters disallowed keys" do
      expect(subject.releases.first).to_not include "git" => "release_repo.git"
      expect(subject.releases.first).to include "name" => "foo", "version" => "latest"
    end
  end

  describe "#meta" do
    let(:stemcell_foo) { { "name" => "foo", "version" => "2" } }
    let(:stemcell_bar) { { "name" => "bar", "version" => "3" } }

    context "1 stemcell" do
      let(:stemcells) { [ stemcell_foo ] }
      its(:meta) { should include "stemcell" => stemcell_foo }
      its(:meta) { should include meta }
    end

    context "multiple stemcells" do
      let(:stemcells) { [ stemcell_foo, stemcell_bar ] }
      its(:meta) { should include "stemcells" => [ stemcell_foo, stemcell_bar ] }
      its(:meta) { should include meta }
    end

    context "meta already containing stemcell" do
      let(:meta) { { "stemcell" => stemcell_bar } }
      let(:stemcells) { [ stemcell_foo ] }
      its(:meta) { should include "stemcell" => stemcell_bar }
    end
  end
end

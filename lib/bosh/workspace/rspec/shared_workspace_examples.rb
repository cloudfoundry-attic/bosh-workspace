require "common/exec"
require "yaml"
require 'semi_semantic/version'
require 'bosh/workspace'
require 'cli'

desc = "behaves as bosh-workspace deployment"
RSpec.shared_examples desc do |deployment_file, result_file, stub_file|
  let(:workdir) { File.expand_path(File.join(deployment_file, '../..')) }
  let(:stub) do
    result = {} unless File.exist?(stub_file)
    result ||= YAML.load_file(stub_file) || {}
    result.merge({'director_uuid' => '00000000-0000-0000-0000-000000000000'})
  end

  subject do
    Bosh::Workspace::ProjectDeployment.new(deployment_file).tap do |d|
      d.stub = stub
      d.validate
    end
  end

  it "is a valid deployment manifest" do
    expect(subject.errors).to eq []
  end

  def merge_templates(deployment, workdir)
    Bosh::Workspace::ManifestBuilder.build(deployment, workdir)
  end

  def prepare_templates(deployment, workdir)
    releases_dir = File.join(workdir, '.releases')
    callback = Bosh::Workspace::GitCredentialsProvider
               .new(File.join(workdir, '.credentials.yml')).callback

    deployment.releases.each do |release|
      Bosh::Workspace::Release.new(release, releases_dir, callback).update_repo
    end
  end

  it "successfully merges deployment templates" do
    expect { prepare_templates(subject, workdir) }.to_not raise_error
    expect { merge_templates(subject, workdir) }.to_not raise_error
    expect(subject.merged_file).to match_manifest result_file
  end
end

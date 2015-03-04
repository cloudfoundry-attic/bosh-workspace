module Bosh::Workspace::Tasks
  describe Deployment do
    subject { Deployment.new(deployment) }
    let(:deployment) do
      {
        "name" => "foo",
        "target" => "foo:bar@example.com:25555",
        "apply_patch" => "tmp/apply_foo_patch.yml",
        "create_patch" => "tmp/create_foo_patch.yml",
        "errands" => ["foo_errand", "bar_errand"]
      }
    end

    describe 'validation' do
      it "validates" do
        expect { subject }.to_not raise_error
      end

      %w(name target).each do |field|
        context "missing #{field}" do
          before { deployment.delete field }
          it { expect { subject }.to raise_error(/#{field}.*missing/i) }
        end
      end

      %w(apply_patch create_patch errands).each do |field|
        context "missing optional #{field}" do
          before { deployment.delete field }
          it { expect { subject }.to_not raise_error }
        end
      end

      context "invalid name" do
        before { deployment["name"] = "foo.yml" }
        it { expect { subject }.to raise_error(/name.*doesn't match regexp/i) }
      end
    end

    describe "#name" do
      before do
        expect(YAML).to receive(:load_file).with("deployments/foo.yml")
          .and_return({ "name" => "foobar1" })
      end

      its(:name) { is_expected.to eq "foobar1" }
    end

    describe "target, username and password" do
      before do
        deployment["target"] = target if defined? target
      end

      its(:target) { is_expected.to eq "example.com:25555" }
      its(:username) { is_expected.to eq "foo" }
      its(:password) { is_expected.to eq "bar" }

      context "default password" do
        let(:target) { "foo@example.com" }
        its(:target) { is_expected.to eq "example.com" }
        its(:username) { is_expected.to eq "foo" }
        its(:password) { is_expected.to eq "admin" }
      end

      context "default username" do
        let(:target) { "example.com:25555" }
        its(:target) { is_expected.to eq "example.com:25555" }
        its(:username) { is_expected.to eq "admin" }
        its(:password) { is_expected.to eq "admin" }
      end
    end

    describe "properties" do
      its(:merged_file) { is_expected.to eq ".deployments/foo.yml" }
      its(:file_name) { is_expected.to eq "foo.yml" }
      its(:errands) { is_expected.to eq ["foo_errand", "bar_errand"] }
      its(:apply_patch) { is_expected.to eq "tmp/apply_foo_patch.yml" }
      its(:create_patch) { is_expected.to eq "tmp/create_foo_patch.yml" }
    end
  end
end

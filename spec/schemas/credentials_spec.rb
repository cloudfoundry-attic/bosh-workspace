module Bosh::Workspace::Schemas
  describe Credentials do
    let(:user_pass_url) { "http://foo" }
    let(:user_pass) do
      { "url" => user_pass_url, "username" => "bar", "password" => "baz" }
    end
    let(:ssh_url) { "ssh://bar" }
    let(:ssh_key) do
      { "url" => ssh_url, "private_key" => "foobarkey" }
    end
    let(:credentials) { [user_pass, ssh_key] }

    subject { Credentials.new.validate(credentials) }

    context "valid credentials" do
      it { expect { subject }.to_not raise_error }
    end

    %w(url username password private_key).each do |field_name|
      context "missing #{field_name}" do
        let(:credentials) do
          [user_pass, ssh_key].map do |c|
            c.delete_if { |k| k == field_name }
          end
        end
        it { expect { subject }.to raise_error(/doesn't validate/i) }
      end
    end

    context "unsupported protocol" do
      let(:ssh_url) { 'git://foo' }
      it { expect { subject }.to raise_error /not supported/ }
    end

    context "http protocol credentials mismatch" do
      let(:ssh_url) { 'http://foo' }
      it { expect { subject }.to raise_error /username\/password/ }
    end

    context "ssh protocol credentials mismatch" do
      let(:user_pass_url) { 'ssh://foo' }
      it { expect { subject }.to raise_error /private_key/ }
    end
  end
end

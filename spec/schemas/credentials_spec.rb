module Bosh::Workspace::Schemas
  describe Credentials do
    let(:username_password) do
      { "url" => "foo", "username" => "bar", "password" => "baz" }
    end
    let(:ssh_key) do
      { "url" => "bar", "private_key" => "foobarkey" }
    end

    subject { Credentials.new.validate(credentials) }

    context "valid credentials" do
      let(:credentials) { [username_password, ssh_key] }
      it { expect { subject }.to_not raise_error }
    end

    %w(url username password private_key).each do |field_name|
      context "missing #{field_name}" do
        let(:credentials) do
          [username_password, ssh_key].map do |c|
            c.delete_if { |k| k == field_name }
          end
        end
        it { expect { subject }.to raise_error(/doesn't validate/i) }
      end
    end
  end
end

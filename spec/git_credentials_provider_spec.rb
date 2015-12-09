module Bosh::Workspace
  describe GitCredentialsProvider do
    let!(:credentials_provider) { GitCredentialsProvider.new(file) }
    let(:file) { "credentials_file" }
    let(:file_exist) { true }
    let(:valid) { true }
    let(:url_protocols) { [] }
    let(:url) { 'http://foo.com/bar.git' }
    let(:user) { nil }
    let(:result) { nil }
    let(:allowed_types) { [:plaintext] }
    let(:credentials) do
      instance_double "Bosh::Workspace::Credentials",
                      :valid? => valid, url_protocols: url_protocols
    end

    subject { credentials_provider.callback.call url, user, allowed_types }

    before do
      allow(Credentials).to receive(:new).and_return(credentials)
      allow(File).to receive(:exist?).and_return(file_exist)
      allow(credentials).to receive(:find_by_url).with(url).and_return(result)
    end

    describe '#callback' do
      context "with sshkey" do
        let(:user) { 'git' }
        let(:result) { { private_key: 'barkey' } }
        let(:allowed_types) { [:ssh_key] }

        it 'returns Rugged sshkey credentials' do
          expect(Rugged::Credentials::SshKey).to receive(:new) do |args|
            expect(args[:username]).to eq user
            expect(IO.read(args[:privatekey])).to eq('barkey')
          end; subject
        end
      end

      context "with username/password" do
        let(:result) { { username: user, password: 'barpw' } }
        let(:allowed_types) { [:plaintext] }

        it 'returns Rugged user password credentials' do
          expect(Rugged::Credentials::UserPassword).to receive(:new) do |args|
            expect(args[:username]).to eq user
            expect(args[:password]).to eq 'barpw'
          end; subject
        end
      end

      context "without credentials file" do
        let(:file_exist) { false }
        it 'raises an error' do
          expect{ subject }.to raise_error /credentials file does not exist/i
        end
      end

      context "with invalid credentials file" do
        let(:valid) { false }
        before { expect(credentials).to receive(:errors) { ['foo error'] } }
        it 'raises an error' do
          expect{ subject }.to raise_error /is not valid/i
        end
      end

      context "without credentials for given url" do
        let(:result) { nil }
        it 'raises an error' do
          expect{ subject }.to raise_error /no credentials found/i
        end
      end

      context "without protocol support" do
        let(:url_protocols) { {"https://foo.com" => :https } }
        before { expect(Rugged).to receive(:features).and_return([]) }
        it 'raises an error' do
          expect{ subject }.to raise_error /requires https support/i
        end
      end
    end
  end
end

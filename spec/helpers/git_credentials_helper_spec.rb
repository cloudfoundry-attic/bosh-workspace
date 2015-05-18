module Bosh::Workspace
  describe GitCredenialsHelper do
    class GitCredenialsHelperTester
      include Bosh::Workspace::GitCredenialsHelper

      attr_reader :work_dir

      def initialize(work_dir)
        @work_dir = work_dir
      end
    end

    let(:work_dir) { asset_dir("manifests-repo") }
    let(:url) { "foo/bar.git" }
    let(:dir) { File.join(work_dir, '.releases', 'foo') }
    let(:repo) { instance_double 'Rugged::Repository' }
    let(:remote) { instance_double 'Rugged::Remote', url: url }
    let(:protocol) { :http }
    let(:git_url) { instance_double 'GitRemoteURL', protocol: protocol }

    before do
      allow(Rugged::Repository).to receive(:new).with(dir).and_return(repo)
      allow(File).to receive(:exist?).with(File.join(dir, '.git')).and_return(dir_exist)
      allow(repo).to receive_message_chain("remotes.[]").and_return(remote)
      allow(repo).to receive_message_chain("remotes.create_anonymous")
        .with(url).and_return(remote)
      allow(repo).to receive_message_chain("references.[].resolve.target_id")
        .and_return(:commit_id)
      allow(remote).to receive(:check_connection).with(:fetch, Hash)
        .and_return(!auth_required, credentials_auth_valid)
      allow(repo).to receive(:checkout).with(:commit_id, strategy: :force)
      allow(GitRemoteUrl).to receive(:new).and_return(git_url)
    end

    def expect_no_credentials
      expect(repo).to receive(:fetch).with('origin', Array, {})
    end

    let(:dir_exist) { true }
    let(:auth_required) { false }
    let(:credentials_auth_valid) { true }

    describe "fetch_repo" do
      subject do
        GitCredenialsHelperTester.new(work_dir).fetch_repo(dir)
      end

      context "with existing repo" do
        it do
          expect_no_credentials
          subject
        end
      end
    end

    describe "fetch_or_clone_repo" do
      subject do
        GitCredenialsHelperTester.new(work_dir).fetch_or_clone_repo(dir, url)
      end

      context "with existing repo" do
        it do
          expect_no_credentials
          subject
        end
      end

      context "repo does not yet exist" do
        let(:dir_exist) { false }

        it "initializes a new repository and sets up a remote" do
          expect(Rugged::Repository).to receive(:init_at).with(dir)
            .and_return(repo)
          expect(repo).to receive_message_chain("remotes.create")
            .with('origin', url)
          expect_no_credentials
          subject
        end
      end

      context "repo requires authentication" do
        let(:auth_required) { true }
        let(:credentials_file_exist) { true }
        let(:credentials_valid) { true }
        let(:credentials) { instance_double "Bosh::Workspace::Credentials" }
        let(:creds_hash) { {} }

        def expect_credentials(credentials)
          expect(repo).to receive(:fetch)
            .with('origin', Array, credentials: credentials)
        end

        before do
          allow(File).to receive(:exist?).with(/.credentials.yml/)
            .and_return(credentials_file_exist)
          allow(Bosh::Workspace::Credentials).to receive(:new)
            .with(/.credentials.yml/).and_return(credentials)
          allow(credentials).to receive(:valid?).and_return(credentials_valid)
          allow(credentials).to receive(:find_by_url)
            .with(url).and_return(creds_hash)
        end

        context "without supported protocol" do
          before do
            expect(Rugged).to receive(:features).and_return([])
          end

          let(:protocol) { :https }

          it "raises" do
            expect { subject }.to raise_error /rugged requires https/i
          end
        end

        context "with git protocol" do
          let(:protocol) { :git }

          it "raises" do
            expect { subject }.to raise_error /not support authentication/i
          end
        end

        context "with sshkey" do
          let(:creds_hash) { { private_key: "foobarkey" } }

          it "uses a key" do
            expect(Rugged::Credentials::SshKey).to receive(:new) do |args|
              expect(IO.read(args[:privatekey])).to eq "foobarkey"
              :ssh_credentials
            end
            expect_credentials :ssh_credentials
            subject
          end
        end

        context "with username/password" do
          let(:creds_hash) { { username: "foo", password: "bar" } }

          it "uses a username/password" do
            expect(Rugged::Credentials::UserPassword).to receive(:new) do |args|
              expect(args[:username]).to eq "foo"
              expect(args[:password]).to eq "bar"
              :user_pw_credentials
            end
            expect_credentials :user_pw_credentials
            subject
          end
        end

        context "with invalid credentials" do
          let(:credentials_auth_valid) { false }

          it "raises and error" do
            expect { subject }.to raise_error /invalid credentials/i
          end
        end

        context "without credentials file" do
          let(:credentials_file_exist) { false }

          it "raises and error" do
            expect { subject }.to raise_error /credentials file does not exist/i
          end
        end

        context "with invalid credentials file" do
          let(:credentials_valid) { false }

          it "raises and error" do
            expect(credentials).to receive(:errors) { ["fooerror"] }
            expect { subject }.to raise_error /not valid/
          end
        end

        context "without credentials for given url" do
          let(:creds_hash) { nil }

          it "raises and error" do
            expect { subject }.to raise_error /no credentials found/i
          end
        end
      end
    end
  end
end

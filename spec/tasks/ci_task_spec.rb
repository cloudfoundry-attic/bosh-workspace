describe 'ci' do
  include_context "rake"

  let(:config) do
    { "target" => target, "deployments" => deployments, "skip_merge" => skip_merge }
  end
  let(:target) { "foo:bar@localhost:25555" }
  let(:deployments) { [{ "name" => "foo" }] }
  let(:skip_merge) { true }
  let(:repo) { instance_double("Git::Base") }

  before do
    allow(YAML).to receive(:load_file).with(".ci.yml").and_return(config)
    allow(Git).to receive(:open).and_return(repo)
  end

  describe ':set_target' do
    subject { rake["ci:set_target"] }

    context "with username, password, hostname and port" do
      let(:target) { "foo:bar@example.com:25555" }
      it "sets target" do
        expect(Bosh::Exec).to receive(:sh).with(/target example.com:25555/)
        expect(Bosh::Exec).to receive(:sh).with(/login foo bar/)
        subject.invoke
      end
    end

    context "with default password" do
      let(:target) { "foo@example.com:25555" }
      it "sets target" do
        expect(Bosh::Exec).to receive(:sh).with(/target example.com:25555/)
        expect(Bosh::Exec).to receive(:sh).with(/login foo admin/)
        subject.invoke
      end
    end

    context "with default password" do
      let(:target) { "foo@example.com:25555" }
      it "sets target" do
        ENV['director_password'] = "env_pw"
        expect(Bosh::Exec).to receive(:sh).with(/target example.com:25555/)
        expect(Bosh::Exec).to receive(:sh).with(/login foo env_pw/)
        subject.invoke
      end
    end
  end

  describe ':deploy_stable' do
    subject { rake["ci:deploy_stable"] }

    it 'runs' do
      expect(repo).to receive(:checkout).with("stable")
      expect(Bosh::Exec).to receive(:sh).with(/deployment foo/)
      expect(Bosh::Exec).to receive(:sh).with(/prepare deployment/)
      expect(IO).to receive(:popen).with(/bosh deploy/).and_yield(["foo"])
      subject.invoke
    end
  end

  describe ':run' do
    subject { rake["ci:run"] }
    let(:already_invoked_tasks) { %w(ci:set_target ci:deploy_stable) }
    let(:deploy_stdout) { ["task 100", "bar"] }

    before do
      expect(repo).to receive(:checkout).with("master")
      expect(Bosh::Exec).to receive(:sh).with(/deployment foo/)
      expect(Bosh::Exec).to receive(:sh).with(/prepare deployment/)
      expect(IO).to receive(:popen).with(/bosh deploy/).and_yield(deploy_stdout)
    end

    it "runs" do
      subject.invoke
    end

    context "with failing deploy" do
      let(:deploy_stdout) { ["task 101", "Task 101 error"] }
      it "fails" do
        expect { subject.invoke }.to raise_error SystemExit
      end
    end

    context "with errands" do
      let(:deployments) { [{ "name" => "foo", "errands" => ["foo", "bar"] }] }
      it "runs and executes errands" do
        expect(Bosh::Exec).to receive(:sh).with(/run errand foo/)
        expect(Bosh::Exec).to receive(:sh).with(/run errand bar/)
        subject.invoke
      end
    end

    context "with create_patch" do
      let(:patch_path) { "foo/bar.yml" }
      let(:deployments) { [{ "name" => "foo", "create_patch" => patch_path }] }

      it "runs and creates patch" do
        expect(Bosh::Exec).to receive(:sh)
          .with(/create deployment patch #{patch_path}/)
        subject.invoke
      end
    end

    context "with apply_patch" do
      let(:patch_path) { "foo/bar.yml" }
      let(:deployments) { [{ "name" => "foo", "apply_patch" => patch_path }] }

      it "applies patch and runs" do
        expect(Bosh::Exec).to receive(:sh)
          .with(/apply deployment patch #{patch_path}/)
        subject.invoke
      end
    end

    context "without skip_merge" do
      let(:config) do
        { "target" => target, "deployments" => deployments }
      end
      let(:branch) { instance_double("Git::Branch") }

      it "runs and merges" do
        expect(repo).to receive(:branch).with("stable").and_return(branch)
        expect(branch).to receive(:merge).with("master")
        subject.invoke
      end

      context "with ENV['skip_merge']" do
        %w(true t yes y 1).each do |val|
          it "runs" do
            ENV['skip_merge'] = val.to_s
            subject.invoke
          end
        end
      end
    end
  end
end

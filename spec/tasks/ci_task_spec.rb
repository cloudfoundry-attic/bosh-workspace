describe 'ci' do
  include_context "rake"

  let(:config) do
    { "target" => target, "deployments" => deployments, "skip_merge" => skip_merge }
  end
  let(:target) { "foo:bar@localhost:25555" }
  let(:deployments) { [{ "name" => "foo" }] }
  let(:skip_merge) { true }
  let(:repo) { instance_double("Git::Base") }
  let(:shell) { instance_double("Bosh::Workspace::Shell") }

  before do
    allow(YAML).to receive(:load_file).with(".ci.yml").and_return(config)
    allow(Git).to receive(:open).and_return(repo)
    allow(Bosh::Workspace::Shell).to receive(:new).and_return(shell)
  end

  def expect_bosh_command(cmd)
    expect(shell).to receive(:run).with(cmd, output_command: true)
  end

  describe ':set_target' do
    subject { rake["ci:set_target"] }

    context "with username, password, hostname and port" do
      let(:target) { "foo:bar@example.com:25555" }
      it "sets target" do
        expect_bosh_command(/target example.com:25555/)
        expect_bosh_command(/login foo bar/)
        subject.invoke
      end
    end

    context "with default password" do
      let(:target) { "foo@example.com:25555" }
      it "sets target" do
        expect_bosh_command(/target example.com:25555/)
        expect_bosh_command(/login foo admin/)
        subject.invoke
      end
    end

    context "with default password" do
      let(:target) { "foo@example.com:25555" }
      it "sets target" do
        ENV['director_password'] = "env_pw"
        expect_bosh_command(/target example.com:25555/)
        expect_bosh_command(/login foo env_pw/)
        subject.invoke
      end
    end
  end

  describe ':deploy_stable' do
    subject { rake["ci:deploy_stable"] }

    it 'runs' do
      expect(repo).to receive(:checkout).with("stable")
      expect_bosh_command(/deployment foo/)
      expect_bosh_command(/prepare deployment/)
      expect(shell).to receive(:run)
        .with(/bosh -n deploy/, {output_command: true, last_number: 1})
      subject.invoke
    end
  end

  describe ':run' do
    subject { rake["ci:run"] }
    let(:already_invoked_tasks) { %w(ci:set_target ci:deploy_stable) }
    let(:deploy_stdout) { "task 100" }

    before do
      expect(repo).to receive(:checkout).with("master")
      expect_bosh_command(/deployment foo/)
      expect_bosh_command(/prepare deployment/)
      expect(shell).to receive(:run)
        .with(/bosh -n deploy/, {output_command: true, last_number: 1})
        .and_return(deploy_stdout)
    end

    it "runs" do
      subject.invoke
    end

    context "with failing deploy" do
      let(:deploy_stdout) { "Task 101 error" }
      it "fails" do
        expect { subject.invoke }.to raise_error SystemExit
      end
    end

    context "with errands" do
      let(:deployments) { [{ "name" => "foo", "errands" => ["foo", "bar"] }] }
      it "runs and executes errands" do
        expect_bosh_command(/run errand foo/)
        expect_bosh_command(/run errand bar/)
        subject.invoke
      end
    end

    context "with create_patch" do
      let(:patch_path) { "foo/bar.yml" }
      let(:deployments) { [{ "name" => "foo", "create_patch" => patch_path }] }

      it "runs and creates patch" do
        expect_bosh_command(/create deployment patch #{patch_path}/)
        subject.invoke
      end
    end

    context "with apply_patch" do
      let(:patch_path) { "foo/bar.yml" }
      let(:deployments) { [{ "name" => "foo", "apply_patch" => patch_path }] }

      it "applies patch and runs" do
        expect_bosh_command(/apply deployment patch #{patch_path}/)
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

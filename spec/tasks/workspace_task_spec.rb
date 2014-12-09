module Bosh::Workspace::Tasks
  describe 'workspace' do
    include_context "rake"

    let(:cli) { instance_double("BoshCommandRunner") }
    let(:deployment) do
      methods = {
        name: "foo-z1",
        target: "example.com:25555",
        username: "foo",
        password: "bar",
        merged_file: ".deployments/foo.yml",
        apply_patch: "tmp/apply_foo_patch.yml",
        create_patch: "tmp/create_foo_patch.yml",
        errands: ["foo_errand", "bar_errand"]
      }
      instance_double("Deployment", methods)
    end

    before do
      allow(YAML).to receive(:load_file).with("deployments.yml")
        .and_return([:deployment])
      allow(BoshCommandRunner).to receive(:new)
        .with("example.com:25555", "foo", "bar").and_return(cli)
      allow(Deployment).to receive(:new)
        .with(:deployment).and_return(deployment)
    end

    def expect_bosh_command(cmd, options = {})
      expect(cli).to receive(:run).with(cmd, options)
    end

    context "with deployments" do
      before do
        expect(cli).to receive(:deployment_file=)
          .with(".deployments/foo.yml")
      end

      describe ':patch' do
        subject { rake["workspace:patch"] }

        it "runs" do
          expect_bosh_command("apply deployment patch tmp/apply_foo_patch.yml")
          expect_bosh_command("create deployment patch tmp/create_foo_patch.yml")
          subject.invoke
        end
      end

      describe ':deploy' do
        subject { rake["workspace:deploy"] }
        let(:already_invoked_tasks) { %w(workspace:target) }
        let(:deploy_stdout) { "task 100" }

        before do
          expect_bosh_command("prepare deployment")
          expect(cli).to receive(:run).with("deploy", last_number: 1)
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
      end

      describe ':verify' do
        subject { rake["workspace:verify"] }

        it "runs and executes errands" do
          expect_bosh_command("run errand foo_errand")
          expect_bosh_command("run errand bar_errand")
          subject.invoke
        end
      end
    end

    describe ':clean' do
      subject { rake["workspace:clean"] }

      it "deletes all deployments" do
        ENV["DESTROY_DEPLOYMENTS"] = "true"
        expect_bosh_command("delete deployment foo-z1 --force", ignore_failures: true)
        subject.invoke
      end

      it "raises error when DESTROY_DEPLOYMENTS is not set" do
        expect { subject.invoke }.to raise_error /destroy_deployments/i
      end

      after { ENV.delete_if { |e| e =~ /DESTROY_DEPLOYMENTS/ } }
    end
  end
end

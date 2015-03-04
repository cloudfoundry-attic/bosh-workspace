module Bosh::Workspace::Tasks
  describe BoshCommandRunner do
    describe "#run" do
      subject { BoshCommandRunner.new "example.com:25555", "foo", "bar" }
      let(:shell) { instance_double("Bosh::Workspace::Shell") }

      before do
        allow(Bosh::Workspace::Shell).to receive(:new).and_return(shell)
      end

      def expect_bosh_command(cmd, options = {})
        options[:output_command] = true
        options[:env] = { "BOSH_USER" => "foo", "BOSH_PASSWORD" => "bar" }
        cmd = "bundle exec bosh -n -t example.com:25555 #{cmd}"
        expect(shell).to receive(:run).with(cmd, options)
      end

      it "runs" do
        expect_bosh_command("foo")
        subject.run "foo"
      end

      context "with deployment_file" do
        it "runs" do
          expect_bosh_command("-d .deployments/foo.yml foo")
          subject.deployment_file = ".deployments/foo.yml"
          subject.run "foo"
        end
      end

      context "with options" do
        it "runs" do
          expect_bosh_command("foo", ignore_failures: true)
          subject.run "foo", ignore_failures: true
        end
      end
    end
  end
end

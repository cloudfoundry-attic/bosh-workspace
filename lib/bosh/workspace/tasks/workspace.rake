namespace :workspace do
  include Bosh::Workspace::Tasks

  desc "Apply or create patches as defined in deployments.yml"
  task :patch do
    with_deployments do |deployment|
      if apply_patch_path = deployment.apply_patch
        bosh "apply deployment patch #{apply_patch_path}"
      end

      if create_patch_path = deployment.create_patch
        bosh "create deployment patch #{create_patch_path}"
      end
    end
  end

  desc "Deploy deployments as defined in deployments.yml"
  task :deploy do
    with_deployments do
      bosh "prepare deployment"
      bosh_deploy
    end
  end

  desc "Verifies deployments by running errands specified in deployments.yml"
  task :run_errands do
    with_deployments do |deployment|
      deployment.errands.each do |errand|
        bosh "run errand #{errand}"
      end if deployment.errands
    end    
  end

  desc "Cleans up by deleting all deployments specified in deployments.yml"
  task :clean do
    unless ENV["DESTROY_DEPLOYMENTS"]
      raise "Set DESTROY_DEPLOYMENTS to confirm deployment destruction"
    end

    with_deployments(set_deployment: false) do |deployment|
      bosh "delete deployment #{deployment.name} --force", ignore_failures: true
    end
  end

  def with_deployments(options = {})
    deployments.each do |d|
      @cli = BoshCommandRunner.new(d.target, d.username, d.password)
      unless options[:set_deployment] == false
        @cli.deployment_file = d.merged_file
      end
      yield d
    end
  end

  def deployments
    @deployments ||= begin
      YAML.load_file("deployments.yml").map { |d| Deployment.new(d) }
    end
  end

  def bosh_deploy
    out = bosh("deploy", last_number: 1)
    exit 1 if out =~ /error/
  end

  def bosh(command, options = {})
    @cli.run command, options
  end
end

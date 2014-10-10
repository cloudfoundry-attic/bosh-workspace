require "git"
require "yaml"
require "membrane"

namespace :ci do
  desc "Run deployment and tests errands as defined in .ci.yml"
  task run: [:set_target, :deploy_stable] do
    repo.checkout 'master'
    deployments.each do |deployment|
      set_deployment(deployment.name)

      if apply_patch_path = deployment.apply_patch
        sh "bosh apply deployment patch #{apply_patch_path}"
      end

      prepare_deployment
      stream_deploy

      deployment.errands.each do |errand|
        sh "bosh run errand #{errand}"
      end

      if create_patch_path = deployment.create_patch
        sh "bosh create deployment patch #{create_patch_path}"
      end
    end

    repo.branch('stable').merge('master') unless skip_merge?
  end

  desc "Sets bosh target specified in .ci.yml also accepts ENV['director_password']"
  task :set_target do
    sh "bosh -n target #{target}"
    sh "bosh -n login #{username} #{password}"
  end

  desc "Deploys from stable branch"
  task :deploy_stable do
    repo.checkout 'stable'
    deployments.each do |name|
      set_deployment(name)
      prepare_deployment
      stream_deploy
    end
  end

  def skip_merge?
    config.skip_merge || ENV['skip_merge'] =~ /^(true|t|yes|y|1)$/i
  end

  def username
    config.target.match(/^([^@:]+)/)[1] || "admin"
  end

  def password
    ENV['director_password'] || config.target.match(/:([^@]+)/) || "admin"
  end

  def target
    config.target.split('@')[1]
  end

  def deployments
    @deployments ||= config.deployments.map { |d| OpenStruct.new(d) }
  end

  def config
    OpenStruct.new(load_config)
  end

  def load_config
    YAML.load_file(".ci.yml").tap { |c| config_schema.validate c }
  end

  def config_schema
    Membrane::SchemaParser.parse do
      { "target"   => String,
        "deployments" => [{
          "name" => String,
          optional("apply_patch") => String,
          optional("create_patch") => String,
          optional("errands") => [String]
        }],
        optional("skip_merge") => bool
      }
    end
  end

  def repo
    @repo ||= Git.open(Dir.getwd)
  end

  def set_deployment(name)
    sh "bosh deployment #{name}"
  end

  def prepare_deployment
    sh "bosh prepare deployment"
  end

  def stream_deploy
    deploy_task = []
    IO.popen("echo 'yes' | bosh deploy") { |f| f.each { |l| puts l; deploy_task << l } }
    exit 1 if deploy_task.last =~ /error/
  end
end

module Bosh::Manifests
  module ProjectDeploymentHelper

    def project_deployment?
      File.exists?(project_deployment_file) &&
        project_deployment_file?(project_deployment_file)
    end

    def project_deployment
      @project_deployment ||= DeploymentManifest.new(project_deployment_file)
    end

    def project_deployment=(deployment)
      @project_deployment = DeploymentManifest.new(deployment)
    end

    def project_deployment_file?(deployment)
      Psych.load(File.read(deployment)).has_key?("templates")
    end

    def require_project_deployment
      unless project_deployment?
        err("Deployment is not a project deployment: #{deployment}")
      end
      validate_project_deployment
    end

    def create_placeholder_deployment
      resolve_director_uuid

      File.open(project_deployment.merged_file, "w") do |file|
        file.write(placeholder_deployment_content)
      end
    end

    def validate_project_deployment
      unless project_deployment.valid?
        say("Validation errors:".make_red)
        project_deployment.errors.each { |error| say("- #{error}") }
        err("'#{project_deployment.file}' is not valid".make_red)
      end
    end

    def build_project_deployment
      resolve_director_uuid

      say("Generating deployment manifest")
      ManifestBuilder.build(project_deployment, work_dir)
      
      if domain_name = project_deployment.domain_name
        say("Transforming to dynamic networking (dns)")
        DnsHelper.transform(project_deployment.merged_file, domain_name)
      end
    end

    def resolve_director_uuid
      use_targeted_director_uuid if director_uuid_current?
    end

    private

    def use_targeted_director_uuid
      no_warden_error unless warden_cpi?
      project_deployment.director_uuid = bosh_uuid
    end

    def no_warden_error
      say("Please put 'director_uuid: #{bosh_uuid}' in '#{deployment}'")
      err("'director_uuid: current' may not be used in production")
    end

    def director_uuid_current?
      project_deployment.director_uuid == "current"
    end

    def warden_cpi?
      bosh_status["cpi"] == "warden"
    end

    def project_deployment_file
      @project_deployment_file ||= begin
        path = File.join(deployment_dir, "../deployments", deployment_basename)
        File.expand_path path
      end
    end

    def deployment_dir
      File.dirname(deployment)
    end

    def deployment_basename
      File.basename(deployment)
    end

    def placeholder_deployment_content
      { "director_uuid" => project_deployment.director_uuid }.to_yaml +
        "# Don't edit; placeholder deployment for: #{project_deployment.file}"
    end

    def bosh_status
      @bosh_status ||= director.get_status
    end

    def bosh_uuid
      bosh_status["uuid"]
    end
  end
end

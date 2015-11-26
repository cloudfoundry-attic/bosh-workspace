require "bosh/workspace"

module Bosh::Cli::Command
  class Prepare < Base
    include Bosh::Cli::Validation
    include Bosh::Workspace
    include ProjectDeploymentHelper
    include ReleaseHelper
    include StemcellHelper

    usage "prepare deployment"
    desc "Resolve deployment requirements"
    option "--local", "only perform local git operations (don't fetch remote)"
    def prepare
      require_project_deployment
      auth_required
      offline! if options[:local]
      nl
      prepare_release_repos
      nl
      prepare_releases
      nl
      prepare_stemcells
    end

    private

    def prepare_release_repos
      project_deployment_releases.each do |release|
        require_git_url_error if release.git_url.nil?
        say "Fetching release '#{release.name.make_green}' to satisfy template references"
        release.update_repo
        print_prepare_release_repo_message(release)
      end
    end

    def print_prepare_release_repo_message(release)
      msg = "Version '#{release.version.to_s.make_green}'"
      msg = "Ref '#{release.ref.make_green}'" if release.ref
      say "#{msg} has been checkout into:"
      say "- #{release.repo_dir}"
    end

    def require_git_url_error
      say "`bosh prepare deployment' can not be used:"
      err("`git:' is missing from `release:'".make_red)
    end

    def prepare_releases
      project_deployment_releases.each do |release|
        prepare_release(release)
      end
    end

    def prepare_release(release)
      if release_uploaded?(release.name, release.version)
        say "Release '#{release.name_version.make_green}' exists"
        say "Skipping upload"
      elsif release.url
        say "Uploading '#{release.url}'"
        release_upload_from_url(release.url)
      else
        say "Uploading '#{release.name_version.make_green}'"
        release_upload(release.manifest_file, release.release_dir)
      end
    end

    def prepare_stemcells
      project_deployment_stemcells.each do |stemcell|
        prepare_stemcell(stemcell)
      end
    end

    def prepare_stemcell(stemcell)
      if stemcell_uploaded?(stemcell.name, stemcell.version)
        say "Stemcell '#{stemcell.name_version.make_green}' exists"
        say "Skipping upload"
      else
        cached_stemcell_upload(stemcell)
      end
    end

    def cached_stemcell_upload(stemcell)
      say "Uploading '#{stemcell.name_version.make_green}'"
      stemcell_upload_url("https://bosh.io/d/stemcells/#{stemcell.name}?v=#{stemcell.version}")
    end

  end
end

require "bosh/workspace"

module Bosh::Cli::Command
  class Prepare < Base
    include Bosh::Cli::Validation
    include Bosh::Workspace
    include ProjectDeploymentHelper
    include GitCredenialsHelper
    include ReleaseHelper
    include StemcellHelper

    usage "prepare deployment"
    desc "Resolve deployment requirements"
    def prepare
      require_project_deployment
      auth_required
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
        fetch_or_clone_repo(release.repo_dir, release.git_url)
        release.update_repo
        msg = "Version '#{release.version.to_s.make_green}'"
        msg = "Ref '#{release.ref.make_green}'" if release.ref
        say "#{msg} has been checkout into:"
        say "- #{release.repo_dir}"
      end
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
      else
        say "Uploading '#{release.name_version.make_green}'"
        release_upload(release.manifest_file)
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
      unless stemcell.downloaded?
        say "Downloading '#{stemcell.name_version.make_green}'"
        stemcell_download(stemcell.file_name)
      end
      say "Uploading '#{stemcell.name_version.make_green}'"
      stemcell_upload(stemcell.file)
    end
  end
end

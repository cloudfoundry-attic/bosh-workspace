module Bosh::Workspace
  module ReleaseHelper
    include ProjectDeploymentHelper

    def release_uploaded?(name, version)
      remote_release = director.get_release(name) rescue nil
      remote_release && remote_release["versions"].include?(version.to_s)
    end

    def release_upload(manifest_file_or_release_url, release_dir)
      Dir.chdir(release_dir) do
        release_cmd.upload(manifest_file_or_release_url)
      end
    end

    def releases_dir
      @releases_dir ||= begin
        FileUtils.mkdir_p(File.join(work_dir, ".releases")).first
      end
    end

    def project_deployment_releases
      project_deployment.releases.map do |r|
        Release.new(r, releases_dir, credentials_callback, offline: offline?)
      end
    end

    def offline!
      @offline = true
    end

    private

    def offline?
      @offline
    end

    def credentials_callback
      @callback ||= GitCredentialsProvider.new(credentials_file).callback
    end

    def credentials_file
      File.join(work_dir, '.credentials.yml')
    end

    def release_cmd
      Bosh::Cli::Command::Release::UploadRelease.new
    end
  end
end

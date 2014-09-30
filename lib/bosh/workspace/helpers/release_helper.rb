module Bosh::Workspace
  module ReleaseHelper
    include ProjectDeploymentHelper

    def release_uploaded?(name, version)
      remote_release = director.get_release(name) rescue nil
      remote_release && remote_release["versions"].include?(version.to_s)
    end

    def release_upload(manifest_file)
      release_cmd.upload(manifest_file)
    end

    def releases_dir
      @releases_dir ||= begin
        FileUtils.mkdir_p(File.join(work_dir, ".releases")).first
      end
    end

    def project_deployment_releases
      @releases ||= begin
        project_deployment.releases.map { |r| Release.new(r, releases_dir) }
      end
    end

    private

    def release_cmd
      @release_cmd ||= Bosh::Cli::Command::Release::UploadRelease.new
    end
  end
end


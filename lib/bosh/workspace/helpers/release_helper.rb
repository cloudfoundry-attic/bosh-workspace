module Bosh::Workspace
  module ReleaseHelper
    include ProjectDeploymentHelper

    def release_uploaded?(name, version)
      remote_release = director.get_release(name) rescue nil
      remote_release && remote_release["versions"].include?(version.to_s)
    end

    def release_upload_from_url(release_url)
      upload_release_cmd.upload(release_url)
    end

    def release_upload(manifest_file, release_dir)
      release_tarball = create_release(manifest_file, release_dir)
      upload_release_cmd.upload(release_tarball)
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

    private

    def create_release(release_manifest, release_dir)
      release_tarball = release_manifest.sub('yml', 'tgz')
      return release_tarball if File.exist?(release_tarball)
      err "Final release tarball missing: #{release_tarball}" if offline?
      create_release_cmd(release_dir).create(release_manifest)
      release_tarball
    end

    def credentials_callback
      @callback ||= GitCredentialsProvider.new(credentials_file).callback
    end

    def credentials_file
      File.join(work_dir, '.credentials.yml')
    end

    def upload_release_cmd
      Bosh::Cli::Command::Release::UploadRelease.new
    end

    def create_release_cmd(release_dir)
      Bosh::Cli::Command::Release::CreateRelease.new.tap do |r|
        r.add_option(:with_tarball, true)
        r.add_option(:dir, release_dir)
      end
    end
  end
end

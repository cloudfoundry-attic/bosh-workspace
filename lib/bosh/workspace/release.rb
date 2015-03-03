require "git"
module Bosh::Workspace
  class Release
    attr_reader :name, :git_uri, :repo_dir, :ref

    def initialize(release, releases_dir)
      @name = release["name"]
      @ref = release["ref"]
      @spec_version = release["version"]
      @git_uri = release["git"]
      @repo_dir = File.join(releases_dir, @name)
      init_repo unless @git_uri.empty?
    end

    def update_repo
      @repo.fetch "origin", tags: true
      @repo.checkout last_commit
      @repo.checkout ref || version_ref
    end

    def manifest_file
      File.join(repo_dir, manifest)
    end

    def manifest
      final_releases[version]
    end

    def name_version
      "#{name}/#{version}"
    end

    def version
      return final_releases.keys.sort.last if @spec_version == "latest"
      unless final_releases[@spec_version.to_i]
        err("Could not find version: #{@spec_version} for release: #{@name}")
      end
      @spec_version.to_i
    end

    private

    # transforms releases/foo-1.yml, releases/bar-2.yml to:
    # { "1" => foo-1.yml, "2" => bar-2.yml }
    def final_releases
      @final_releases ||= begin
        Hash[Dir[File.join(repo_dir, "releases", "*.yml")]
          .reject { |f| f[/index.yml/] }
          .map { |dir| File.join("releases", File.basename(dir)) }
          .map { |version| [version[/(\d+)/].to_i, version] }]
      end
    end

    def last_commit
      @repo.log.object("origin").first
    end

    def version_ref
      @repo.log.object(manifest).first
    end

    def init_repo
      if File.directory?(repo_dir)
        @repo ||= Git.open(repo_dir)
      else
        releases_dir = File.dirname(repo_dir)
        FileUtils.mkdir_p(releases_dir)
        @repo = Git.clone(@git_uri, @name, path: releases_dir)
      end
    end
  end
end

module Bosh::Workspace
  class Release
    attr_reader :name, :git_url, :repo_dir

    def initialize(release, releases_dir)
      @name = release["name"]
      @ref = release["ref"]
      @spec_version = release["version"]
      @git_url = release["git"]
      @repo_dir = File.join(releases_dir, @name)
    end

    def update_repo
      repo.checkout ref || repo.head.target_id, strategy: :force
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

    def ref
      @ref && repo.lookup(@ref).oid
    end

    private

    def repo
      @repo ||= Rugged::Repository.new(repo_dir)
    end

    # transforms releases/foo-1.yml, releases/bar-2.yml to:
    # { "1" => foo-1.yml, "2" => bar-2.yml }
    def final_releases
      @final_releases ||= begin
        releases_dir = File.directory?(File.join(repo_dir, "releases", @name))? "releases/#{@name}" : "releases"

        Hash[Dir[File.join(repo_dir, releases_dir, "*.yml")]
          .reject { |f| f[/index.yml/] }
          .map { |dir| File.join(releases_dir, File.basename(dir)) }
          .map { |version| [version[/(\d+)/].to_i, version] }]
      end
    end

    def version_ref
      Rugged::Blame.new(repo, manifest).first[:final_commit_id]
    end
  end
end

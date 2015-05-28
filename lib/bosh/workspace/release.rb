module Bosh::Workspace
  class Release
    attr_reader :name, :git_url, :repo_dir

    def initialize(release, releases_dir)
      @name = release["name"]
      @ref = release["ref"]
      @path = release["path"]
      @spec_version = release["version"].to_s
      @git_url = release["git"]
      @repo_dir = File.join(releases_dir, @name)
    end

    def update_repo
      last_error = ''
      hash = ref || release[:commit]
      begin
        repo.checkout hash, strategy: :force
        repo.reset hash, :hard
      rescue Rugged::IndexError => e
        raise e if e.message == last_error
        last_error = e.message
        retry
      end
    end

    def update_submodule(submodule)
      submodule.repository.checkout submodule.head_oid, strategy: :force
    end

    def required_submodules
      required = []
      symlink_templates.each do |template|
        submodule = submodule_for(template)
        if submodule
          required.push(submodule)
        end
      end
      required
    end

    def manifest_file
      File.join(repo_dir, manifest)
    end

    def manifest
      release[:manifest]
    end

    def name_version
      "#{name}/#{version}"
    end

    def version
      release[:version]
    end

    def ref
      @ref && repo.lookup(@ref).oid
    end

    def release_dir
      @path ? File.join(@repo_dir, @path) : @repo_dir
    end

    private

    def repo
      @repo ||= Rugged::Repository.new(repo_dir)
    end

    def new_style_repo
      base = @path ? File.join(@path, 'releases') : 'releases'
      dir = File.join(repo_dir, base, @name)
      File.directory?(dir) && !File.symlink?(dir)
    end

    def releases_dir
      dir = new_style_repo ? "releases/#{@name}" : "releases"
      @path ? File.join(@path, dir) : dir
    end

    def releases_tree
      repo.lookup(repo.head.target.tree.path(releases_dir)[:oid])
    end

    # transforms releases/foo-1.yml, releases/bar-2.yml to:
    # [ { version: "1", commit: ee8d52f5d, manifest: releases/foo-1.yml } ]
    def final_releases
      @final_releases ||= begin
        final_releases = {}
        releases_tree.walk_blobs(:preorder) do |_, entry|
          next if entry[:filemode] == 40960 # Skip symlinks
          path = File.join(releases_dir, entry[:name])
          blame = Rugged::Blame.new(repo, path)[0]
          time = blame[:final_signature][:time]
          commit_id = blame[:final_commit_id]
          manifest = blame[:orig_path]
          version = entry[:name][/#{@name}-(.+)\.yml/, 1]
          final_releases[time] = {
            version: version, manifest: manifest, commit: commit_id
          }
        end

        final_releases.sort_by { |k, _| k }
          .map { |a| a[1] }.reject { |f| f[:manifest][/index.yml/] }
      end
    end

    def release
      return final_releases.last if @spec_version == "latest"
      release = final_releases.find { |v| v[:version] == @spec_version }
      unless release
        err("Could not find version: #{@spec_version} for release: #{@name}")
      end
      release
    end

    def templates_dir
      File.join(repo.workdir, "templates")
    end

    def symlink_target(file)
      if File.readlink(file).start_with?("/")
        return File.readlink(file)
      else
        return File.expand_path(File.join(File.dirname(file), File.readlink(file)))
      end
    end

    def submodule_for(file)
      repo.submodules.each do |submodule|
        if file.start_with?(File.join(repo.workdir, submodule.path))
          return submodule
        end
      end
      false
    end

    def symlink_templates
      templates = []
      if FileTest.exists?(templates_dir)
        Find.find(templates_dir) do |file|
          if FileTest.symlink?(file)
            templates.push(symlink_target(file))
          end
        end
      end
      templates
    end
  end
end

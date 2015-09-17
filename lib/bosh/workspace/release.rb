module Bosh::Workspace
  class Release
    REFSPEC = ['HEAD:refs/remotes/origin/HEAD']
    attr_reader :name, :git_url, :repo_dir

    def initialize(release, releases_dir, credentials_callback)
      @name                 = release["name"]
      @ref                  = release["ref"]
      @path                 = release["path"]
      @spec_version         = release["version"].to_s
      @git_url              = release["git"]
      @repo_dir             = File.join(releases_dir, @name)
      @url                  = release["url"]
      @credentials_callback = credentials_callback
      fetch_repo
    end

    def update_repo
      hash = ref || release[:commit]
      update_repo_with_ref(repo, hash)
      update_submodules
    end

    def update_submodules
      required_submodules.each do |submodule|
        fetch_repo(submodule_repo(submodule.path, submodule.url))
        update_repo_with_ref(submodule.repository, submodule.head_oid)
      end
    end

    def required_submodules
      required = []
      symlink_templates.each do |template|
        submodule = submodule_for(template)
        required.push(submodule) if submodule
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

    def url
      @url && @url.gsub("^VERSION^", version)
    end

    private

    def submodule_repo(path, url)
      dir = File.join(@repo_dir, path)
      repo_exists?(dir) ? open_repo(dir) : init_repo(dir, url)
    end

    def repo
      repo_exists? ? open_repo : init_repo
    end

    def fetch_repo(repo = repo)
      repo.fetch('origin', REFSPEC, credentials: @credentials_callback)
      commit = repo.references['refs/remotes/origin/HEAD'].resolve.target_id
      repo.checkout_tree commit, strategy: :force
      repo.checkout commit, strategy: :force
    end

    def repo_exists?(dir = @repo_dir)
      File.exist?(File.join(dir, '.git'))
    end

    def open_repo(dir = @repo_dir)
      Rugged::Repository.new(dir)
    end

    def init_repo(dir = @repo_dir, url = @git_url)
      FileUtils.mkdir_p File.dirname(dir)
      Rugged::Repository.init_at(dir).tap do |repo|
        repo.remotes.create('origin', url)
      end
    end

    def update_repo_with_ref(repository, ref)
      repository.checkout_tree ref, strategy: :force
      repository.checkout ref, strategy: :force
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
        final_releases = []
        releases_tree.walk_blobs(:preorder) do |_, entry|
          next if entry[:filemode] == 40960 # Skip symlinks
          path = File.join(releases_dir, entry[:name])
          blame = Rugged::Blame.new(repo, path).reduce { |memo, hunk|
            if memo.nil? || hunk[:final_signature][:time] > memo[:final_signature][:time]
              hunk
            else
              memo
            end
          }
          commit_id = blame[:final_commit_id]
          manifest = blame[:orig_path]
          version = entry[:name][/#{@name}-(.+)\.yml/, 1]
          if ! version.nil?
            final_releases.push({
              version: version, manifest: manifest, commit: commit_id
            })
          end
        end

        final_releases.sort! { |a, b| a[:version].to_i <=> b[:version].to_i }
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

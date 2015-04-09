require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "archive/zip"
require "rugged"

task :default => :spec
RSpec::Core::RakeTask.new

namespace :git_assets do
  desc "Extract git assets used in specs to tmp/git_assets"
  task :extract do
    FileUtils.rm_rf(tmp_workdir) if File.exist?(tmp_workdir)
    git_spec_assets.each do |name, file|
      target = File.join(tmp_workdir, name)
      Dir.mktmpdir(name) do |tmp_dir|
        Archive::Zip.extract(file, tmp_dir)
        Rugged::Repository.clone_at(tmp_dir, target)
      end
      puts "Extracted #{name}.zip"
    end
    puts "All git assets have been extracted into: #{tmp_workdir}"
  end

  desc "Update git assets with changes made in tmp/git_assets"
  task :update do
    tmp_workdirs.each do |name, dir|
      archive = File.join(git_spec_assets_dir, "#{name}.zip")
      Archive::Zip.archive(archive, dir)
      puts "Updated #{name}.zip"
    end
  end

  def tmp_workdir
    File.join(project_root, "tmp/git_assets")
  end

  def tmp_workdirs
    Dir["#{tmp_workdir}/*"].map do |file|
      [ File.basename(file, ".*"), File.join(file, ".git") ]
    end.to_h
  end

  def git_spec_assets_dir
    File.join(project_root, "spec/assets")
  end

  def git_spec_assets
    Dir[File.join(git_spec_assets_dir, "/*repo*.zip")].map do |file|
      [ File.basename(file, ".*"), file ]
    end.to_h
  end

  def project_root
    File.dirname(__FILE__)
  end
end

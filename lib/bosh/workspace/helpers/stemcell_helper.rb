module Bosh::Workspace
  module StemcellHelper
    def stemcell_download(stemcell_name)
      Dir.chdir(stemcells_dir) do
        say "Downloading stemcell '#{stemcell_name}'"
        nl
        stemcell_cmd.download_public(stemcell_name)
      end
    end

    def stemcell_upload(stemcell_file)
      say "Uploading stemcell '#{File.basename(stemcell_file)}'"
      nl
      stemcell_cmd.upload(stemcell_file)
    end

    def stemcell_uploaded?(name, version)
      existing = director.list_stemcells.select do |sc|
        sc['name'] == name && sc['version'] == version
      end

      !existing.empty? 
    end

    def stemcells_dir
      @stemcells_dir ||= begin
        FileUtils.mkdir_p(File.join(work_dir, ".stemcells")).first
      end
    end

    private

    def stemcell_cmd
      @stemcell_cmd ||= Bosh::Cli::Command::Stemcell.new
    end
  end
end

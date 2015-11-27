require 'httpclient'
require 'cli/download_with_progress'

module Bosh::Workspace
  module StemcellHelper
    include ProjectDeploymentHelper

    def stemcell_download(stemcell)
      Dir.chdir(stemcells_dir) do
        say "Downloading stemcell '#{stemcell.name}' version '#{stemcell.version}'"
        nl
        download_stemcell_from_bosh_io(stemcell)
      end
    end

    def stemcell_upload(stemcell_file)
      say "Uploading stemcell '#{File.basename(stemcell_file)}'"
      nl
      stemcell_cmd.upload(stemcell_file)
    end

    def stemcell_uploaded?(name, version)
      existing = director.list_stemcells.select do |sc|
        sc['name'] == name && sc['version'] == version.to_s
      end

      !existing.empty? 
    end

    def stemcells_dir
      @stemcells_dir ||= begin
        FileUtils.mkdir_p(File.join(work_dir, ".stemcells")).first
      end
    end

    def project_deployment_stemcells
      @stemcells ||= begin
        project_deployment.stemcells.map { |s| Stemcell.new(s, stemcells_dir) }
      end
    end

    def download_stemcell_from_bosh_io(stemcell)

      url=sprintf("https://bosh.io/d/stemcells/%s?v=%s", stemcell.name, stemcell.version)

      response = HTTPClient.new.head(url)

      if response.status == 302
        location = response.header['location'][0]
        response2 = HTTPClient.new.head(location)

        if response2.status == 200
          size = response2.header['Content-Length'][0]
        else
          say("HTTP #{response2.status} : #{location}".make_red)
          say(" - redirected from: : #{url}".make_red)
          return
        end
      else
        say("HTTP #{response.status} : #{url} (expecting 302 - redirect)".make_red)
        return
      end

      download_with_progress = Bosh::Cli::DownloadWithProgress.new(location, size.to_i)
      download_with_progress.perform
    end

    private

    def stemcell_cmd
      @stemcell_cmd ||= Bosh::Cli::Command::Stemcell.new
    end

  end

end

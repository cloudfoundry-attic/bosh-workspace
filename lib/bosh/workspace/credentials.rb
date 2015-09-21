module Bosh::Workspace
  class Credentials
    include Bosh::Cli::Validation
    include GitProtocolHelper
    attr_reader :raw_credentials

    def initialize(file)
      @raw_credentials = YAML.load_file file
    end

    def perform_validation(options = {})
      Schemas::Credentials.new.validate raw_credentials
    rescue Membrane::SchemaValidationError => e
      errors << e.message
    end

    def find_by_url(url)
      credentials[url]
    end

    def url_protocols
      Hash[raw_credentials.map { |c| [c['url'], git_protocol_from_url(c['url'])] }]
    end

    private

    def credentials
      @credentials ||= begin
        Hash[raw_credentials.map { |c| [c.delete('url'), symbolize_keys(c)] }]
      end
    end

    def symbolize_keys(hash)
      hash.each_with_object({}) { |(k, v), h| h[k.to_sym] = v }
    end
  end
end

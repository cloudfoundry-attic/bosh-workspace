module Bosh::Workspace
  class MergeTool
    include Bosh::Exec

    attr_accessor :name, :version

    def initialize(merge_tool = nil)
      @name, @version = case merge_tool
      when Hash
        [merge_tool['name'], merge_tool['version']]
      when String
        [merge_tool, 'current']
      else
        ['spiff', 'current']
      end

      unless available_tool_names.include?(@name)
        say("#{@name} is not supported, please specify spiff or spruce instead.".make_red)
      end
    end

    def available_tool_names
      %w(spiff spruce)
    end

    def merge(templates, target_file)
      check_tool_version if version != 'current'
      run_merge_tool(:merge, templates) do |output|
        File.open(target_file, 'w') { |file| file.write(output) }
      end
    end

    private

    def run_merge_tool(verb, params = [])
      params.map!(&:shellescape)
      cmd = [name, verb.to_s] + params + ['2>&1']
      sh(cmd.join(" "), :yield => :on_false) do |result|
        command_not_found if result.not_found?
        command_failed(result.command, result.output) if result.failed?
        yield result.output
      end
    end

    def check_tool_version
      run_merge_tool('-v') do |output|
        actual_version = output.match(/(\d+\.\d+\.\d+)/).to_a.first
        if actual_version.nil? || actual_version != version
          warning "Deployment requires #{name} to have version #{version}. " +
                  "Your actual #{name} version is #{actual_version}."
        end
      end
    end

    def command_not_found(command)
      say("Can't find #{name} in $PATH".make_red)
      say("Go to #{installation_instructions_url} for installation instructions")
      err("Please make sure #{name} is installed")
    end

    def installation_instructions_url
      case name
      when 'spiff' then 'spiff.cfapps.io'
      when 'spruce' then 'https://github.com/geofffranks/spruce#installation'
      end
    end

    def command_failed(command, output)
      say("Command failed: '#{command}'")
      err(output)
    end    
  end
end

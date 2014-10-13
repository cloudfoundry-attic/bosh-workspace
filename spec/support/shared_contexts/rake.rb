require "rake"

shared_context "rake" do
  let(:rake)      { Rake::Application.new }
  let(:task_name) { self.class.top_level_description }
  let(:task_path) { "lib/bosh/workspace/tasks/#{task_name.split(":").first}" }

  def loaded_files_excluding_current_rake_file
    $".reject { |file| file == File.join(project_root, "#{task_path}.rake") }
  end

  def clear_main_instance_vars
    TOPLEVEL_BINDING.eval('self').instance_variables.each do |var|
      TOPLEVEL_BINDING.eval('self').remove_instance_variable(var)
    end
  end

  def setup_already_invoked_tasks
    if defined? already_invoked_tasks
      rake.instance_variable_get(:@tasks).each do |name, task|
        if already_invoked_tasks.include? name
          task.instance_variable_set(:@already_invoked, true)
        end
      end
    end
  end

  before do
    Rake.application = rake
    Rake.application.rake_require(task_path, [project_root], loaded_files_excluding_current_rake_file)
    setup_already_invoked_tasks
  end

  after do
    clear_main_instance_vars
  end
end

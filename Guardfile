# workaround for https://github.com/guard/guard-rspec/issues/348
rspec_results = File.expand_path('rspec_guard_result')
guard :rspec, cmd: 'bundle exec rspec --fail-fast', notification: false, results_file: rspec_results do
  watch(%r{^spec/(.+_spec)\.rb$})
  watch(%r{^lib/bosh/cli/commands/(.+)\.rb$})    { |m| "spec/commands/#{m[1]}_spec.rb" }
  watch(%r{^lib/bosh/workspace/(.+)\.rb$})    { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^lib/bosh/workspace/(.+)\.rake$})    { |m| "spec/#{m[1]}_task_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end

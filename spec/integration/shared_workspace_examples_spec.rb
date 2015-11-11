require 'bosh/workspace/rspec'

describe "rspec shared bosh-workspace example" do
  deployment = {
    'name' => 'foo',
    'releases' => [],
    'stemcells' => [],
    'templates' => [
      'deployment.yml'
    ],
    'meta' => {
      'foo' => 'bar'
    }
  }
  deployment_template = {
    'director_uuid' => '(( merge ))',
    'name' => '(( merge ))',
    'releases' => '(( merge ))',
    'jobs' => []
  }
  stub = { 'name' => 'bar' }

  result = {
    'director_uuid' => '00000000-0000-0000-0000-000000000000',
    'name' => 'bar',
    'releases' => [],
    'jobs' => []
  }

  deployment_file = get_tmp_yml_file_path(deployment).tap do |d|
    templates_path = File.expand_path('../../templates', d)
    FileUtils.mkdir_p templates_path
    IO.write(
      File.join(templates_path, 'deployment.yml'),
      deployment_template.to_yaml
    )
  end

  include_examples(
    "behaves as bosh-workspace deployment",
    deployment_file,
    get_tmp_yml_file_path(result),
    get_tmp_yml_file_path(stub)
  )
end

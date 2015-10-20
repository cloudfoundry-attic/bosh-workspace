module Bosh::Workspace
  describe MergeTool do
    
    subject { Bosh::Workspace::MergeTool.new(tool_name) }
    let(:templates) { %w(foo.yml bar.yml) }
    let(:target_file) { 'spiffed_manifest.yml' }
    let(:path) { asset_dir('bin') }

    around do |example|
      original_path = ENV['PATH']
      ENV['PATH'] = path
      example.run
      ENV['PATH'] = original_path
    end

    context 'unknown tool' do
      let(:tool_name) { 'unknown-tool' }
      it 'raises an error' do
        expect { subject.merge(templates, target_file).to raise_error }
      end
    end

    %w(spiff spruce).each do |tool_name|
      context tool_name do        
        let(:file) { instance_double("File") }
        before do
          allow(File).to receive(:open).with(target_file, 'w').and_yield(file)
          allow(file).to receive(:write).with(output)
        end

        context 'using tool name as a string' do
          before do
            expect(subject).to receive(:sh).at_least(:once).with(*args).and_yield(result)
          end

          let(:result) { Bosh::Exec::Result.new(tool_name, output, 0, false) }
          let(:args) { [/#{tool_name} merge/, Hash] }
          let(:tool_name) { tool_name }
    
          context 'not found error' do
            let(:path) { asset_dir('empty_bin') }
            let(:result) { Bosh::Exec::Result.new(tool_name, 'command not found', 1, false) }
  
            it 'raises an error' do
              expect(subject).to receive(:say).with(/Command failed/)
              expect { subject.merge(templates, target_file) }
                .to raise_error /command not found/
            end
          end
    
          describe '#merge' do
            let(:output) { "---\n{}" }
  
            it 'merges manifests' do
              subject.merge(templates, target_file)
            end
  
            context 'spaces in template paths' do
              let(:templates) { ['space test/foo space test.yml'] }
              let(:args) { [/space\\ test\/foo\\ space\\ test.yml/, Hash] }
  
              it 'merges manifests' do
                subject.merge(templates, target_file)
              end
            end
          end
        end
      

        context 'using tool name as a hash with version and name' do
          subject { Bosh::Workspace::MergeTool.new('name' => tool_name, 'version' => '0.1.0') }
          let(:result) { Bosh::Exec::Result.new(tool_name, output, 0, false) }

          before do
            expect(subject).to receive(:sh).with(/#{tool_name} -v/, Hash).and_yield(result)
            expect(subject).to receive(:sh).with(/#{tool_name} merge/, Hash).and_yield(result)
          end

          describe 'with correct version' do
            let(:output) { "#{tool_name} version 0.1.0" }
            it 'merges manifests' do
              subject.merge(templates, target_file)
            end
          end

          describe 'with wrong version' do
            let(:output) { "#{tool_name} version 0.2.0" }
            it 'merges manifests' do
              expect(subject).to receive(:warning).with(/0\.2\.0/)
              subject.merge(templates, target_file)
            end
          end

        end
      end
    end
  end
end
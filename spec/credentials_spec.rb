module Bosh::Workspace
  describe Credentials do
    let(:credentials) do
      [{ "url" => "foo", "private_key" => "foobarkey" }]
    end

    before do
      expect(YAML).to receive(:load_file).with(:file).and_return(credentials)
    end

    subject do
      Credentials.new(:file)
    end

    describe '#find_by_url' do
      it "returns credentials when found" do
        expect(subject.find_by_url("foo")).to eq({ private_key: "foobarkey" })
      end

      it "returns nil when not found" do
        expect(subject.find_by_url("bar")).to be nil
      end
    end

    describe '#perform_validation' do
      context "valid" do
        it "validates" do
          allow_any_instance_of(Schemas::Credentials)
            .to receive(:validate).with(credentials)
          expect(subject).to be_valid
        end
      end

      context "invalid" do
        it "has errors" do
          allow_any_instance_of(Schemas::Credentials)
            .to receive(:validate).with(credentials)
            .and_raise(Membrane::SchemaValidationError.new("foo"))
          expect(subject).to_not be_valid
          expect(subject.errors).to include "foo"
        end
      end
    end
  end
end

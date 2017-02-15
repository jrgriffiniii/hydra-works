require 'spec_helper'
require 'hydra/works/pcdm_use_validator'

describe Hydra::Works::PcdmUseValidator do
  let(:pcdm_use_validator) { described_class.new(file_set) }
  let(:file_set) { double }
  let(:file1) { double }
  let(:file2) { double }
  before do
    # Stub the config and allowed PCDM uses
    pcdm_use_validator.instance_variable_set("@config", pcdm_types_yml: [])
    pcdm_use_validator.instance_variable_set("@allowed_pcdm_uses", ["valid type"])
  end

  describe '#validate!' do
    context "with an invalid pcdm use" do
      it 'raises an InvalidPcdmUse error' do
        allow(file_set).to receive(:files).and_return([file1])
        allow(file1).to receive(:type).and_return("invalid type")
        expect { pcdm_use_validator.validate! }.to raise_error Hydra::Works::PcdmUseValidator::InvalidPcdmUse
      end
    end
    context "with a duplicate pcdm use" do
      xit "raises a DuplicatePcdmUse error" do
        allow(file_set).to receive(:files).and_return([file1, file2])
        allow(file1).to receive(:type).and_return("valid type")
        allow(file2).to receive(:type).and_return("valid type")

        expect { pcdm_use_validator.validate! }.to raise_error Hydra::Works::PcdmUseValidator::DuplicatePcdmUse
      end
    end
  end

  describe '.validate!' do
    xit 'instantiates the class with the FileSet instance and calls #validate!'
  end
end

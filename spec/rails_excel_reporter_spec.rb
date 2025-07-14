require 'spec_helper'

RSpec.describe RailsExcelReporter do
  describe 'configuration' do
    it 'has a default configuration' do
      expect(RailsExcelReporter.configuration).to be_a(RailsExcelReporter::Configuration)
    end

    it 'can be configured' do
      RailsExcelReporter.configure do |config|
        config.date_format = '%d/%m/%Y'
        config.streaming_threshold = 500
      end

      expect(RailsExcelReporter.config.date_format).to eq('%d/%m/%Y')
      expect(RailsExcelReporter.config.streaming_threshold).to eq(500)
    end
  end

  describe 'version' do
    it 'has a version number' do
      expect(RailsExcelReporter::VERSION).not_to be nil
    end
  end
end

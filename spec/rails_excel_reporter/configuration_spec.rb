require 'spec_helper'

RSpec.describe RailsExcelReporter::Configuration do
  let(:config) { RailsExcelReporter::Configuration.new }

  describe 'default values' do
    it 'has default date format' do
      expect(config.date_format).to eq('%Y-%m-%d')
    end

    it 'has default streaming threshold' do
      expect(config.streaming_threshold).to eq(1000)
    end

    it 'has default styles' do
      expect(config.default_styles).to be_a(Hash)
      expect(config.default_styles[:header]).to include(:bg_color, :fg_color, :bold)
      expect(config.default_styles[:cell]).to include(:border)
    end

    it 'has default temp directory' do
      expect(config.temp_directory).to eq(Dir.tmpdir)
    end
  end

  describe 'customization' do
    it 'allows setting custom date format' do
      config.date_format = '%d/%m/%Y'
      expect(config.date_format).to eq('%d/%m/%Y')
    end

    it 'allows setting custom streaming threshold' do
      config.streaming_threshold = 500
      expect(config.streaming_threshold).to eq(500)
    end

    it 'allows setting custom temp directory' do
      config.temp_directory = '/custom/temp'
      expect(config.temp_directory).to eq('/custom/temp')
    end

    it 'allows setting custom default styles' do
      custom_styles = {
        header: { bg_color: 'FF0000' },
        cell: { border: { style: :medium } }
      }
      config.default_styles = custom_styles
      expect(config.default_styles).to eq(custom_styles)
    end
  end
end

RSpec.describe RailsExcelReporter do
  describe 'configuration' do
    it 'returns the same configuration instance' do
      config1 = RailsExcelReporter.configuration
      config2 = RailsExcelReporter.configuration
      expect(config1).to be(config2)
    end

    it 'allows configuration via block' do
      RailsExcelReporter.configure do |config|
        config.date_format = '%d-%m-%Y'
        config.streaming_threshold = 2000
      end

      expect(RailsExcelReporter.config.date_format).to eq('%d-%m-%Y')
      expect(RailsExcelReporter.config.streaming_threshold).to eq(2000)
    end

    it 'provides config alias' do
      expect(RailsExcelReporter.config).to be(RailsExcelReporter.configuration)
    end
  end
end

require 'spec_helper'

RSpec.describe RailsExcelReporter::ControllerHelpers do
  let :controller_class do
    Class.new do
      include RailsExcelReporter::ControllerHelpers

      attr_accessor :response

      def initialize
        @response = MockResponse.new
      end

      def send_data(data, options = {})
        @sent_data = data
        @send_options = options
      end

      def response_body=(body)
        @response.body = body
      end

      attr_reader :sent_data, :send_options
    end
  end

  let :mock_response do
    Class.new do
      attr_accessor :headers, :body

      def initialize
        @headers = {}
      end
    end
  end

  let(:controller) { controller_class.new }

  let :report_class do
    Class.new RailsExcelReporter::Base do
      attributes :id, :name
    end
  end

  let :sample_data do
    [
      OpenStruct.new(id: 1, name: 'John'),
      OpenStruct.new(id: 2, name: 'Jane')
    ]
  end

  let(:report) { report_class.new sample_data }

  before do
    stub_const 'MockResponse', mock_response
  end

  describe '#send_excel_report' do
    it 'sends Excel data with default filename' do
      controller.send_excel_report report

      expect(controller.sent_data).to be_a(String)
      expect(controller.send_options[:filename]).to match(/\.xlsx$/)
      expect(controller.send_options[:type]).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      expect(controller.send_options[:disposition]).to eq('attachment')
    end

    it 'sends Excel data with custom filename' do
      controller.send_excel_report report, filename: 'custom_report.xlsx'

      expect(controller.send_options[:filename]).to eq('custom_report.xlsx')
    end

    it 'sends Excel data with custom disposition' do
      controller.send_excel_report report, disposition: 'inline'

      expect(controller.send_options[:disposition]).to eq('inline')
    end
  end

  describe '#stream_excel_report' do
    it 'sets up streaming response headers' do
      controller.stream_excel_report report

      expect(controller.response.headers['Content-Type']).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      expect(controller.response.headers['Content-Disposition']).to match(/attachment; filename=/)
      expect(controller.response.headers['Content-Transfer-Encoding']).to eq('binary')
      expect(controller.response.headers['Last-Modified']).to be_present
      expect(controller.response.body).to be_a(StringIO)
    end

    it 'uses custom filename in Content-Disposition' do
      controller.stream_excel_report report, filename: 'custom_stream.xlsx'

      expect(controller.response.headers['Content-Disposition']).to include('custom_stream.xlsx')
    end
  end

  describe '#excel_report_response' do
    it 'uses send_excel_report for small reports' do
      allow(report).to receive(:should_stream?).and_return(false)
      expect(controller).to receive(:send_excel_report).with(report, {})

      controller.excel_report_response report
    end

    it 'uses stream_excel_report for large reports' do
      allow(report).to receive(:should_stream?).and_return(true)
      expect(controller).to receive(:stream_excel_report).with(report, {})

      controller.excel_report_response report
    end

    it 'passes options to the appropriate method' do
      allow(report).to receive(:should_stream?).and_return(false)
      expect(controller).to receive(:send_excel_report).with(report, { filename: 'test.xlsx' })

      controller.excel_report_response report, filename: 'test.xlsx'
    end
  end
end

require 'spec_helper'

RSpec.describe RailsExcelReporter::Base do
  let :sample_data do
    [
      OpenStruct.new(id: 1, name: 'John Doe', email: 'john@example.com', created_at: Time.parse('2024-01-01')),
      OpenStruct.new(id: 2, name: 'Jane Smith', email: 'jane@example.com', created_at: Time.parse('2024-01-02')),
      OpenStruct.new(id: 3, name: 'Bob Johnson', email: 'bob@example.com', created_at: Time.parse('2024-01-03'))
    ]
  end

  let :report_class do
    Class.new RailsExcelReporter::Base do
      attributes :id, :name, :email

      def name
        "#{object.name} (Custom)"
      end
    end
  end

  let(:report) { report_class.new sample_data }

  describe 'class methods' do
    describe '.attributes' do
      it 'defines attributes for the report' do
        expect(report_class.attributes).to contain_exactly(
          { name: :id, header: 'Id' },
          { name: :name, header: 'Name' },
          { name: :email, header: 'Email' }
        )
      end
    end

    describe '.attribute' do
      it 'adds a single attribute with custom header' do
        klass = Class.new RailsExcelReporter::Base
        klass.attribute :custom_field, header: 'Custom Header'

        expect(klass.attributes).to contain_exactly(
          { name: :custom_field, header: 'Custom Header' }
        )
      end
    end
  end

  describe 'instance methods' do
    describe '#initialize' do
      it 'initializes with collection' do
        expect(report.collection).to eq(sample_data)
      end

      it 'accepts custom worksheet name' do
        custom_report = report_class.new sample_data, worksheet_name: 'Custom Sheet'
        expect(custom_report.worksheet_name).to eq('Custom Sheet')
      end

      it 'accepts progress callback' do
        callback = proc { |progress| }
        custom_report = report_class.new(sample_data, &callback)
        expect(custom_report.progress_callback).to eq(callback)
      end
    end

    describe '#filename' do
      it 'generates a filename with timestamp' do
        allow(Time).to receive(:now).and_return(Time.parse('2024-01-15'))
        expect(report.filename).to match(/report_report_2024_01_15\.xlsx/)
      end
    end

    describe '#to_h' do
      it 'returns hash representation' do
        hash = report.to_h
        expect(hash).to include(
          :worksheet_name,
          :attributes,
          :data,
          :collection_size,
          :streaming
        )
      end
    end

    describe '#collection_size' do
      it 'returns the size of the collection' do
        expect(report.collection_size).to eq(3)
      end
    end

    describe '#should_stream?' do
      it 'returns false for small collections' do
        expect(report.should_stream?).to be false
      end

      it 'returns true for large collections' do
        large_data = (1..2000).map { |i| OpenStruct.new id: i, name: "User #{i}" }
        large_report = report_class.new large_data
        expect(large_report.should_stream?).to be true
      end
    end

    describe 'Excel generation' do
      it 'generates Excel file' do
        file = report.file
        expect(file).to be_a(Tempfile)
        expect(file.size).to be > 0
      end

      it 'generates Excel binary data' do
        xlsx_data = report.to_xlsx
        expect(xlsx_data).to be_a(String)
        expect(xlsx_data.size).to be > 0
        expect(xlsx_data[0, 4]).to eq("PK\x03\x04")
      end

      it 'saves to file' do
        temp_path = '/tmp/test_report.xlsx'
        report.save_to temp_path
        expect(File.exist?(temp_path)).to be true
        expect(File.size(temp_path)).to be > 0
        File.delete temp_path
      end
    end

    describe 'custom methods' do
      it 'calls custom methods for attribute values' do
        report_data = report.to_h[:data]
        expect(report_data[0][1]).to eq('John Doe (Custom)')
        expect(report_data[1][1]).to eq('Jane Smith (Custom)')
      end
    end
  end

  describe 'error handling' do
    it 'raises error when no attributes are defined' do
      empty_class = Class.new RailsExcelReporter::Base
      empty_report = empty_class.new []

      expect { empty_report.to_xlsx }.to raise_error(RuntimeError, /No attributes defined/)
    end
  end

  describe 'callbacks' do
    let :callback_class do
      Class.new RailsExcelReporter::Base do
        attributes :id, :name

        attr_reader :before_render_called, :after_render_called,
                    :before_row_calls, :after_row_calls

        def initialize(*args)
          super
          @before_render_called = false
          @after_render_called = false
          @before_row_calls = []
          @after_row_calls = []
        end

        def before_render
          @before_render_called = true
        end

        def after_render
          @after_render_called = true
        end

        def before_row(object)
          @before_row_calls << object
        end

        def after_row(object)
          @after_row_calls << object
        end
      end
    end

    let(:callback_report) { callback_class.new sample_data }

    it 'calls all callbacks in correct order' do
      callback_report.to_xlsx

      expect(callback_report.before_render_called).to be true
      expect(callback_report.after_render_called).to be true
      expect(callback_report.before_row_calls).to eq(sample_data)
      expect(callback_report.after_row_calls).to eq(sample_data)
    end
  end
end

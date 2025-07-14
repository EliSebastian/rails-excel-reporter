require 'spec_helper'

RSpec.describe RailsExcelReporter::Streaming do
  let(:small_data) do
    (1..10).map { |i| OpenStruct.new(id: i, name: "User #{i}") }
  end

  let(:large_data) do
    (1..2000).map { |i| OpenStruct.new(id: i, name: "User #{i}") }
  end

  let(:report_class) do
    Class.new(RailsExcelReporter::Base) do
      attributes :id, :name
    end
  end

  describe 'streaming threshold' do
    it 'has default streaming threshold' do
      expect(report_class.streaming_threshold).to eq(RailsExcelReporter.config.streaming_threshold)
    end

    it 'can set custom streaming threshold' do
      report_class.streaming_threshold = 500
      expect(report_class.streaming_threshold).to eq(500)
    end
  end

  describe '#should_stream?' do
    it 'returns false for small collections' do
      report = report_class.new(small_data)
      expect(report.should_stream?).to be false
    end

    it 'returns true for large collections' do
      report = report_class.new(large_data)
      expect(report.should_stream?).to be true
    end
  end

  describe '#collection_size' do
    it 'calculates size for arrays' do
      report = report_class.new(small_data)
      expect(report.collection_size).to eq(10)
    end

    it 'uses count method when available' do
      mock_collection = double('Collection')
      allow(mock_collection).to receive(:count).and_return(100)

      report = report_class.new(mock_collection)
      expect(report.collection_size).to eq(100)
    end

    it 'falls back to size method' do
      mock_collection = double('Collection')
      allow(mock_collection).to receive(:respond_to?).with(:count).and_return(false)
      allow(mock_collection).to receive(:respond_to?).with(:size).and_return(true)
      allow(mock_collection).to receive(:size).and_return(50)

      report = report_class.new(mock_collection)
      expect(report.collection_size).to eq(50)
    end
  end

  describe '#stream_data' do
    it 'yields each item in small collections' do
      report = report_class.new(small_data)
      yielded_items = []

      report.stream_data do |item|
        yielded_items << item
      end

      expect(yielded_items).to eq(small_data)
    end

    it 'uses find_each for large ActiveRecord-like collections' do
      mock_collection = double('ActiveRecord Collection')
      allow(mock_collection).to receive(:respond_to?).with(:count).and_return(true)
      allow(mock_collection).to receive(:count).and_return(2000)
      allow(mock_collection).to receive(:respond_to?).with(:find_each).and_return(true)

      yielded_items = []
      allow(mock_collection).to receive(:find_each).with(batch_size: 1000) do |&block|
        large_data.each(&block)
      end

      report = report_class.new(mock_collection)

      report.stream_data do |item|
        yielded_items << item
      end

      expect(yielded_items.size).to eq(2000)
    end

    it 'returns enumerator when no block given' do
      report = report_class.new(small_data)
      enumerator = report.stream_data

      expect(enumerator).to be_a(Enumerator)
      expect(enumerator.to_a).to eq(small_data)
    end
  end

  describe '#with_progress_tracking' do
    it 'tracks progress and yields items with progress info' do
      report = report_class.new(small_data)
      progress_updates = []

      report.with_progress_tracking do |_item, progress|
        progress_updates << progress
      end

      expect(progress_updates.size).to eq(10)
      expect(progress_updates.first.current).to eq(1)
      expect(progress_updates.first.total).to eq(10)
      expect(progress_updates.first.percentage).to eq(10.0)
      expect(progress_updates.last.current).to eq(10)
      expect(progress_updates.last.percentage).to eq(100.0)
    end

    it 'calls progress callback when provided' do
      callback_calls = []
      callback = proc { |progress| callback_calls << progress }

      report = report_class.new(small_data, &callback)

      report.with_progress_tracking do |item, progress|
        # Just iterate
      end

      expect(callback_calls.size).to eq(10)
      expect(callback_calls.first.current).to eq(1)
      expect(callback_calls.last.current).to eq(10)
    end
  end
end

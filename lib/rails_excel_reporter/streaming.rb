module RailsExcelReporter
  module Streaming
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def streaming_threshold
        @streaming_threshold || RailsExcelReporter.config.streaming_threshold
      end

      def streaming_threshold=(value)
        @streaming_threshold = value
      end
    end

    def should_stream?
      collection_size >= self.class.streaming_threshold
    end

    def collection_size
      return @collection_size if defined?(@collection_size)

      @collection_size = calculate_collection_size
    end

    private

    def calculate_collection_size
      return @collection.count if @collection.respond_to? :count
      return @collection.size if @collection.respond_to? :size
      return @collection.length if @collection.respond_to? :length

      @collection.to_a.size
    end

    public

    def stream_data(&block)
      return enum_for :stream_data unless block_given?

      if should_stream?
        stream_large_dataset(&block)
      else
        stream_small_dataset(&block)
      end
    end

    def with_progress_tracking
      return enum_for :with_progress_tracking unless block_given?

      total, current = collection_size, 0
      stream_data do |item|
        current += 1
        progress = build_progress_info current, total
        @progress_callback&.call progress
        yield item, progress
      end
    end

    def build_progress_info(current, total)
      percentage = (current.to_f / total * 100).round 2
      OpenStruct.new current: current, total: total, percentage: percentage
    end

    def stream_large_dataset(&block)
      if @collection.respond_to? :find_each
        stream_with_find_each(&block)
      else
        stream_with_fallback(&block)
      end
    end

    private

    def stream_with_find_each(&block)
      @collection.find_each(batch_size: 1000, &block)
    rescue ArgumentError
      stream_with_fallback(&block)
    end

    def stream_with_fallback(&block)
      if @collection.respond_to? :each
        @collection.each(&block)
      else
        @collection.to_a.each(&block)
      end
    end

    def stream_small_dataset(&block)
      if @collection.respond_to? :each
        @collection.each(&block)
      else
        @collection.to_a.each(&block)
      end
    end
  end
end

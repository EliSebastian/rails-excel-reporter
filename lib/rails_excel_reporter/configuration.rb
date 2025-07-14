module RailsExcelReporter
  class Configuration
    attr_accessor :default_styles, :date_format, :streaming_threshold, :temp_directory

    def initialize
      @default_styles = {
        header: {
          bg_color: '4472C4',
          fg_color: 'FFFFFF',
          bold: true,
          border: { style: :thin, color: '000000' }
        },
        cell: {
          border: { style: :thin, color: 'CCCCCC' }
        }
      }
      @date_format = '%Y-%m-%d'
      @streaming_threshold = 1000
      @temp_directory = nil
    end

    def temp_directory
      @temp_directory || Dir.tmpdir
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def config
      configuration
    end
  end
end

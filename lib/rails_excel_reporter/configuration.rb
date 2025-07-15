module RailsExcelReporter
  class Configuration
    attr_accessor :default_styles, :date_format, :streaming_threshold, :temp_directory

    def initialize
      @default_styles = default_style_config
      @date_format = '%Y-%m-%d'
      @streaming_threshold = 1000
      @temp_directory = nil
    end

    def temp_directory
      @temp_directory || Dir.tmpdir
    end

    private

    def default_style_config
      {
        header: header_style,
        cell: cell_style
      }
    end

    def header_style
      {
        bg_color: '4472C4',
        fg_color: 'FFFFFF',
        bold: true,
        border: { style: :thin, color: '000000' }
      }
    end

    def cell_style
      {
        border: { style: :thin, color: 'CCCCCC' }
      }
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

    def config
      configuration
    end
  end
end

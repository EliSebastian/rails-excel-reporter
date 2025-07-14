require 'caxlsx'
require 'tempfile'
require 'ostruct'
require 'stringio'
require_relative 'styling'
require_relative 'streaming'

module RailsExcelReporter
  class Base
    include Styling
    include Streaming

    attr_reader :collection, :worksheet_name, :progress_callback

    def initialize(collection, worksheet_name: nil, &progress_callback)
      @collection = collection
      @worksheet_name = worksheet_name || default_worksheet_name
      @progress_callback = progress_callback
      @rendered = false
    end

    def self.attributes(*attrs)
      if attrs.empty?
        @attributes ||= []
      else
        @attributes = attrs.map do |attr|
          case attr
          when Symbol
            { name: attr, header: attr.to_s.humanize }
          when Hash
            symbolize_hash_keys(attr)
          else
            { name: attr.to_sym, header: attr.to_s.humanize }
          end
        end
      end
    end

    def self.symbolize_hash_keys(hash)
      result = {}
      hash.each do |key, value|
        result[key.to_sym] = value
      end
      result
    end

    def self.attribute(name, options = {})
      @attributes ||= []
      @attributes << { name: name.to_sym, header: options[:header] || name.to_s.humanize }
    end

    def self.inherited(subclass)
      super
      subclass.instance_variable_set :@attributes, @attributes.dup if @attributes
    end

    def attributes
      self.class.attributes
    end

    def file
      render unless @rendered
      @tempfile
    end

    def to_xlsx
      render unless @rendered
      @tempfile.rewind
      @tempfile.read
    end

    def save_to(path)
      File.open path, 'wb' do |file|
        file.write to_xlsx
      end
    end

    def filename
      timestamp = Time.now.strftime(RailsExcelReporter.config.date_format).gsub '-', '_'
      "#{worksheet_name.parameterize}_report_#{timestamp}.xlsx"
    end

    def stream
      StringIO.new to_xlsx
    end

    def to_h
      {
        worksheet_name: worksheet_name,
        attributes: attributes,
        data: collection_data,
        collection_size: collection_size,
        streaming: should_stream?
      }
    end

    def before_render; end

    def after_render; end

    def before_row(object); end

    def after_row(object); end

    private

    def default_worksheet_name
      if self.class.name
        self.class.name.demodulize.underscore.humanize
      else
        'Report'
      end
    end

    def render
      validate_attributes!

      before_render

      @tempfile = Tempfile.new [filename.gsub('.xlsx', ''), '.xlsx'],
                               RailsExcelReporter.config.temp_directory

      package = ::Axlsx::Package.new
      workbook = package.workbook

      worksheet = workbook.add_worksheet name: worksheet_name

      add_headers worksheet
      add_data_rows worksheet

      package.serialize @tempfile.path

      @rendered = true

      after_render
    end

    def validate_attributes!
      raise 'No attributes defined. Use `attributes` class method to define columns.' if attributes.empty?
    end

    def add_headers(worksheet)
      header_values = attributes.map { |attr| attr[:header] }
      header_style = build_caxlsx_style get_header_style

      if header_style.any?
        style_id = worksheet.workbook.styles.add_style header_style
        worksheet.add_row header_values, style: style_id
      else
        worksheet.add_row header_values
      end

      worksheet.auto_filter = "A1:#{column_letter attributes.size}1"
    end

    def add_data_rows(worksheet)
      with_progress_tracking do |object, _progress|
        before_row object

        row_values = attributes.map do |attr|
          get_attribute_value object, attr[:name]
        end

        row_styles = attributes.map do |attr|
          style_options = build_caxlsx_style get_column_style(attr[:name])
          worksheet.workbook.styles.add_style style_options if style_options.any?
        end

        worksheet.add_row row_values, style: row_styles

        after_row object
      end
    end

    def get_attribute_value(object, attribute_name)
      if respond_to? attribute_name
        @object = object
        result = send attribute_name
        @object = nil
        result
      elsif object.respond_to? attribute_name
        object.send attribute_name
      elsif object.respond_to? :[]
        object[attribute_name] || object[attribute_name.to_s]
      end
    end

    attr_reader :object

    def collection_data
      @collection_data ||= stream_data.map do |item|
        attributes.map do |attr|
          get_attribute_value item, attr[:name]
        end
      end
    end

    def column_letter(column_number)
      result = ''
      while column_number > 0
        column_number -= 1
        result = ((column_number % 26) + 65).chr + result
        column_number /= 26
      end
      result
    end
  end

  ReportBase = Base
end

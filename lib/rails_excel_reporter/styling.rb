module RailsExcelReporter
  module Styling
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def style(target, options = {})
        @styles ||= {}
        @styles[target.to_sym] = options
      end

      def styles
        @styles ||= {}
      end

      def inherited(subclass)
        super
        subclass.instance_variable_set :@styles, @styles.dup if @styles
      end
    end

    def apply_style(worksheet, cell_range, style_name)
      style_options = self.class.styles[style_name.to_sym] || {}
      return unless style_options.any?

      worksheet.add_style cell_range, style_options
    end

    def build_caxlsx_style(style_options)
      caxlsx_options = {}

      caxlsx_options[:bg_color] = style_options[:bg_color] if style_options[:bg_color]

      caxlsx_options[:fg_color] = style_options[:fg_color] if style_options[:fg_color]

      caxlsx_options[:b] = style_options[:bold] if style_options[:bold]

      caxlsx_options[:i] = style_options[:italic] if style_options[:italic]

      caxlsx_options[:alignment] = style_options[:alignment] if style_options[:alignment]

      caxlsx_options[:border] = style_options[:border] if style_options[:border]

      caxlsx_options[:sz] = style_options[:font_size] if style_options[:font_size]

      caxlsx_options[:font_name] = style_options[:font_name] if style_options[:font_name]

      caxlsx_options
    end

    def merge_styles(*style_names)
      merged = {}
      style_names.each do |style_name|
        style_options = self.class.styles[style_name.to_sym] || {}
        merged = deep_merge_hashes merged, style_options
      end
      merged
    end

    def get_column_style(column_name)
      column_style = self.class.styles[column_name.to_sym] || {}
      default_style = RailsExcelReporter.config.default_styles[:cell] || {}
      deep_merge_hashes default_style, column_style
    end

    def get_header_style
      header_style = self.class.styles[:header] || {}
      default_style = RailsExcelReporter.config.default_styles[:header] || {}
      deep_merge_hashes default_style, header_style
    end

    private

    def deep_merge_hashes(hash1, hash2)
      result = hash1.dup
      hash2.each do |key, value|
        result[key] = if result[key].is_a?(Hash) && value.is_a?(Hash)
                        deep_merge_hashes result[key], value
        else
                        value
        end
      end
      result
    end
  end
end

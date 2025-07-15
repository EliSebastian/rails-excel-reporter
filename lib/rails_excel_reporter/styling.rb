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
      apply_style_mappings caxlsx_options, style_options
      caxlsx_options
    end

    private

    def apply_style_mappings(caxlsx_options, style_options)
      style_mappings.each do |from_key, to_key|
        caxlsx_options[to_key] = style_options[from_key] if style_options[from_key]
      end
    end

    def style_mappings
      {
        bg_color: :bg_color, fg_color: :fg_color, bold: :b, italic: :i,
        alignment: :alignment, border: :border, font_size: :sz, font_name: :font_name
      }
    end

    public

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
        result[key] = merge_hash_value result[key], value
      end
      result
    end

    def merge_hash_value(existing_value, new_value)
      if existing_value.is_a?(Hash) && new_value.is_a?(Hash)
        deep_merge_hashes existing_value, new_value
      else
        new_value
      end
    end
  end
end

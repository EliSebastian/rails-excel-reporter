require 'rails/generators'
require 'rails/generators/named_base'

module Rails
  module Generators
    class ReportGenerator < NamedBase
      source_root File.expand_path('templates', __dir__)

      argument :attributes, type: :array, default: [], banner: 'field:type field:type'

      def create_report_file
        template 'report.rb.erb', File.join('app/reports', class_path, "#{file_name}_report.rb")
      end

      private

      def report_class_name
        "#{class_name}Report"
      end

      def parsed_attributes
        attributes.map do |attr|
          { name: attr.name, type: attr.type }
        end
      end

      def attribute_names
        parsed_attributes.map { |attr| ":#{attr[:name]}" }.join(', ')
      end
    end
  end
end

require 'active_support/core_ext/string'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/time'
require 'tmpdir'

module RailsExcelReporter
  class Error < StandardError; end
  class AttributeNotFoundError < Error; end
  class InvalidConfigurationError < Error; end
end

require 'rails_excel_reporter/version'
require 'rails_excel_reporter/configuration'
require 'rails_excel_reporter/styling'
require 'rails_excel_reporter/streaming'
require 'rails_excel_reporter/base'
require 'rails_excel_reporter/controller_helpers'

require 'rails_excel_reporter/railtie' if defined?(Rails)

require 'rails/railtie'

module RailsExcelReporter
  class Railtie < Rails::Railtie
    initializer 'rails_excel_reporter.configure_rails_initialization' do |app|
      app.config.paths.add 'app/reports', eager_load: true
    end

    initializer 'rails_excel_reporter.include_controller_helpers' do
      ActiveSupport.on_load :action_controller do
        include RailsExcelReporter::ControllerHelpers
      end
    end

    config.after_initialize do
      configure_reports_path if rails_application_available?
    end

    private

    def self.rails_application_available?
      defined?(Rails.application) && Rails.application
    end

    def self.configure_reports_path
      reports_path = Rails.root.join 'app/reports'
      setup_reports_path reports_path if Rails.application.paths['app/reports']
    rescue StandardError => e
      log_configuration_warning e
    end

    def self.setup_reports_path(reports_path)
      app_reports_paths = Rails.application.paths['app/reports']

      unless app_reports_paths.paths.include? reports_path.to_s
        app_reports_paths << reports_path.to_s
      end

      app_reports_paths.eager_load! if app_reports_paths.respond_to? :eager_load!
    end

    def self.log_configuration_warning(error)
      return unless Rails.logger

      Rails.logger.warn "RailsExcelReporter: Failed to configure app/reports path: #{error.message}"
    end
  end
end

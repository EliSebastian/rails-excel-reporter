require 'rails/railtie'

module RailsExcelReporter
  class Railtie < Rails::Railtie
    initializer 'rails_excel_reporter.configure_rails_initialization' do |app|
      app.config.paths.add 'app/reports', eager_load: true
    end

    initializer 'rails_excel_reporter.include_controller_helpers' do
      ActiveSupport.on_load(:action_controller) do
        include RailsExcelReporter::ControllerHelpers
      end
    end

    config.after_initialize do
      if defined?(Rails.application) && Rails.application
        begin
          reports_path = Rails.root.join('app/reports')

          if Rails.application.paths['app/reports']
            unless Rails.application.paths['app/reports'].paths.include?(reports_path.to_s)
              Rails.application.paths['app/reports'] << reports_path.to_s
            end

            if Rails.application.paths['app/reports'].respond_to?(:eager_load!)
              Rails.application.paths['app/reports'].eager_load!
            end
          end
        rescue StandardError => e
          Rails.logger.warn("RailsExcelReporter: Failed to configure app/reports path: #{e.message}") if Rails.logger
        end
      end
    end
  end
end

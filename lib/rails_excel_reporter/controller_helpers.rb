module RailsExcelReporter
  module ControllerHelpers
    def send_excel_report(report, options = {})
      filename = options[:filename] || report.filename
      disposition = options[:disposition] || 'attachment'

      send_data(
        report.to_xlsx,
        filename: filename,
        type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        disposition: disposition
      )
    end

    def stream_excel_report(report, options = {})
      filename = options[:filename] || report.filename

      response.headers['Content-Type'] = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      response.headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
      response.headers['Content-Transfer-Encoding'] = 'binary'
      response.headers['Last-Modified'] = Time.now.httpdate

      self.response_body = report.stream
    end

    def excel_report_response(report, options = {})
      if report.should_stream?
        stream_excel_report(report, options)
      else
        send_excel_report(report, options)
      end
    end
  end
end

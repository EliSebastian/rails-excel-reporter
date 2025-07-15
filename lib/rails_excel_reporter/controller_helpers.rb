module RailsExcelReporter
  module ControllerHelpers
    def send_excel_report(report, options = {})
      filename = options[:filename] || report.filename
      disposition = options[:disposition] || 'attachment'

      send_data \
        report.to_xlsx,
        filename: filename,
        type: excel_content_type,
        disposition: disposition
    end

    def stream_excel_report(report, options = {})
      filename = options[:filename] || report.filename
      set_excel_response_headers filename
      self.response_body = report.stream
    end

    def excel_report_response(report, options = {})
      if report.should_stream?
        stream_excel_report report, options
      else
        send_excel_report report, options
      end
    end

    private

    def set_excel_response_headers(filename)
      response.headers['Content-Type'] = excel_content_type
      response.headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
      response.headers['Content-Transfer-Encoding'] = 'binary'
      response.headers['Last-Modified'] = Time.now.httpdate
    end

    def excel_content_type
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    end
  end
end

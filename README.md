# Rails Excel Reporter

[![Gem Version](https://badge.fury.io/rb/rails-excel-reporter.svg)](https://badge.fury.io/rb/rails-excel-reporter)
[![Build Status](https://github.com/rails-excel-reporter/rails-excel-reporter/workflows/CI/badge.svg)](https://github.com/rails-excel-reporter/rails-excel-reporter/actions)

A Ruby gem that integrates seamlessly with Ruby on Rails to generate Excel reports (.xlsx format) using a simple DSL. Features include streaming for large datasets, custom styling, callbacks, and Rails helpers.

## Features

- 🚀 **Simple DSL** - Define reports with a clean, intuitive syntax
- 📊 **Excel Generation** - Create .xlsx files using the powerful caxlsx gem
- 🎨 **Custom Styling** - Apply styles to headers, columns, and cells
- 🔄 **Streaming Support** - Handle large datasets efficiently with streaming
- 📱 **Rails Integration** - Auto-registers with Rails, includes controller helpers
- 🔧 **Callbacks** - Hook into the generation process with before/after callbacks
- 🎯 **Flexible Data Sources** - Works with ActiveRecord, arrays, and any enumerable
- 📁 **Rails Generator** - Scaffold reports quickly with `rails g report`

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails-excel-reporter'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install rails-excel-reporter
```

## Quick Start

### 1. Create a Report

Create a report in `app/reports/`:

```ruby
class UserReport < RailsExcelReporter::Base
  attributes :id, :name, :email, :created_at
  
  def created_at
    object.created_at.strftime("%Y-%m-%d")
  end
end
```

### 2. Use in Controller

```ruby
class ReportsController < ApplicationController
  def users
    @users = User.active.order(:created_at)
    report = UserReport.new(@users)
    send_excel_report(report)
  end
end
```

### 3. Generate with Rails Generator

```bash
rails g report User name:string email:string role:string
```

This creates `app/reports/user_report.rb` with the basic structure.

## Basic Usage

### Defining Attributes

```ruby
class ProductReport < RailsExcelReporter::Base
  # Simple attributes
  attributes :id, :name, :price
  
  # Custom headers
  attributes :id, { name: :product_name, header: "Product Name" }, :price
  
  # Or use individual attribute method
  attribute :sku, header: "SKU Code"
end
```

### Custom Methods

Override attribute methods to customize output:

```ruby
class OrderReport < RailsExcelReporter::Base
  attributes :id, :customer_name, :total, :status
  
  def customer_name
    "#{object.customer.first_name} #{object.customer.last_name}"
  end
  
  def total
    "$#{object.total.round(2)}"
  end
  
  def status
    object.status.upcase
  end
end
```

### Data Sources

Works with various data sources:

```ruby
# ActiveRecord collections
report = UserReport.new(User.active)

# Arrays
users = [
  { id: 1, name: "John", email: "john@example.com" },
  { id: 2, name: "Jane", email: "jane@example.com" }
]
report = UserReport.new(users)

# Any enumerable
report = UserReport.new(csv_data.lazy.map(&:to_h))
```

## Advanced Features

### Streaming for Large Datasets

Automatically handles large datasets with streaming:

```ruby
class LargeDataReport < RailsExcelReporter::Base
  attributes :id, :name, :data
  
  # Customize streaming threshold (default: 1000)
  self.streaming_threshold = 5000
end

# Usage with progress tracking
report = LargeDataReport.new(huge_dataset) do |progress|
  puts "Processing: #{progress.current}/#{progress.total} (#{progress.percentage}%)"
end
```

### Custom Styling

Apply custom styles to headers and columns:

```ruby
class StyledReport < RailsExcelReporter::Base
  attributes :id, :name, :email, :status
  
  # Header styling
  style :header, {
    bg_color: "4472C4",
    fg_color: "FFFFFF",
    bold: true,
    font_size: 12
  }
  
  # Column-specific styling
  style :id, {
    alignment: { horizontal: :center },
    font_size: 10
  }
  
  style :status, {
    bold: true,
    bg_color: "E7E6E6"
  }
end
```

### Callbacks

Hook into the generation process:

```ruby
class CallbackReport < RailsExcelReporter::Base
  attributes :id, :name, :email
  
  def before_render
    Rails.logger.info "Starting report generation at #{Time.current}"
  end
  
  def after_render
    Rails.logger.info "Report generated successfully"
  end
  
  def before_row(object)
    # Called before each row is processed
  end
  
  def after_row(object)
    # Called after each row is processed
  end
end
```

## Controller Integration

### Helper Methods

The gem provides several helper methods for controllers:

```ruby
class ReportsController < ApplicationController
  def download_users
    report = UserReport.new(User.all)
    
    # Simple download
    send_excel_report(report)
    
    # With custom filename
    send_excel_report(report, filename: "users_#{Date.current}.xlsx")
    
    # Stream large reports
    stream_excel_report(report)
    
    # Automatic streaming based on size
    excel_report_response(report)
  end
end
```

### Response Methods

Available response methods:

```ruby
# Basic file download
send_excel_report(report)

# Streaming response (for large files)
stream_excel_report(report)

# Automatic selection based on report size
excel_report_response(report)
```

## API Reference

### Report Instance Methods

```ruby
report = UserReport.new(users)

# Get the generated file
file = report.file  # Returns Tempfile

# Get binary data
xlsx_data = report.to_xlsx  # Returns String

# Save to specific path
report.save_to("/path/to/file.xlsx")

# Get suggested filename
filename = report.filename  # Returns "user_report_2024_01_15.xlsx"

# Get IO stream
stream = report.stream  # Returns StringIO

# Get hash representation
hash = report.to_h  # Returns Hash with metadata
```

### Configuration

Configure the gem globally:

```ruby
# config/initializers/rails_excel_reporter.rb
RailsExcelReporter.configure do |config|
  config.default_styles = {
    header: {
      bg_color: "2E75B6",
      fg_color: "FFFFFF",
      bold: true
    },
    cell: {
      border: { style: :thin, color: "CCCCCC" }
    }
  }
  
  config.date_format = "%d/%m/%Y"
  config.streaming_threshold = 2000
  config.temp_directory = Rails.root.join("tmp", "reports")
end
```

## Error Handling

The gem includes comprehensive error handling:

```ruby
begin
  report = UserReport.new(users)
  report.to_xlsx
rescue RailsExcelReporter::AttributeNotFoundError => e
  Rails.logger.error "Missing attribute: #{e.message}"
rescue RailsExcelReporter::InvalidConfigurationError => e
  Rails.logger.error "Configuration error: #{e.message}"
rescue RailsExcelReporter::Error => e
  Rails.logger.error "Report generation failed: #{e.message}"
end
```

## Performance Considerations

### Streaming

For large datasets (>1000 records by default), the gem automatically uses streaming:

```ruby
# This will stream automatically
large_report = UserReport.new(User.limit(10000))
large_report.should_stream?  # => true
```

### Memory Usage

The gem is designed to be memory-efficient:

- Uses streaming for large datasets
- Lazy evaluation where possible
- Efficient Excel generation with caxlsx
- Automatic garbage collection of temporary files

## Testing

### Test Helpers

The gem includes test helpers for easier testing:

```ruby
RSpec.describe UserReport do
  let(:users) { create_list(:user, 3) }
  let(:report) { UserReport.new(users) }
  
  describe "#to_xlsx" do
    it "generates Excel file" do
      xlsx_data = report.to_xlsx
      expect(xlsx_data).to be_present
      expect(xlsx_data[0, 4]).to eq("PK\x03\x04") # ZIP signature
    end
  end
  
  describe "#filename" do
    it "generates appropriate filename" do
      expect(report.filename).to match(/user_report_\d{4}_\d{2}_\d{2}\.xlsx/)
    end
  end
end
```

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/rails_excel_reporter/base_spec.rb

# Run with coverage
bundle exec rspec --format documentation
```

## Examples

### Basic Report

```ruby
class ProductReport < RailsExcelReporter::Base
  attributes :id, :name, :price, :category
  
  def price
    "$#{object.price.round(2)}"
  end
  
  def category
    object.category.name
  end
end

# Usage
products = Product.includes(:category).order(:name)
report = ProductReport.new(products)
report.save_to("products.xlsx")
```

### Advanced Report with Styling

```ruby
class SalesReport < RailsExcelReporter::Base
  attributes :date, :product, :quantity, :revenue, :profit
  
  style :header, {
    bg_color: "1F4E79",
    fg_color: "FFFFFF",
    bold: true,
    font_size: 14
  }
  
  style :revenue, {
    bg_color: "E2EFDA",
    alignment: { horizontal: :right }
  }
  
  style :profit, {
    bg_color: "FCE4D6",
    alignment: { horizontal: :right }
  }
  
  def date
    object.created_at.strftime("%Y-%m-%d")
  end
  
  def product
    object.product.name
  end
  
  def revenue
    "$#{object.revenue.round(2)}"
  end
  
  def profit
    "$#{object.profit.round(2)}"
  end
  
  def before_render
    Rails.logger.info "Generating sales report for #{collection.count} records"
  end
end
```

### Streaming Report with Progress

```ruby
class MassiveDataReport < RailsExcelReporter::Base
  attributes :id, :data, :processed_at
  
  self.streaming_threshold = 10000
  
  def processed_at
    object.processed_at.strftime("%Y-%m-%d %H:%M:%S")
  end
end

# Usage with progress tracking
report = MassiveDataReport.new(huge_dataset) do |progress|
  puts "Progress: #{progress.percentage}% (#{progress.current}/#{progress.total})"
end
```

## Requirements

- Ruby 2.7+
- Rails 6.0+
- caxlsx ~> 4.0

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create new Pull Request

## Development

```bash
# Clone the repository
git clone https://github.com/rails-excel-reporter/rails-excel-reporter.git
cd rails-excel-reporter

# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run linter
bundle exec rubocop

# Generate documentation
bundle exec yard
```

## License

This gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Support

- **Issues**: [GitHub Issues](https://github.com/rails-excel-reporter/rails-excel-reporter/issues)
- **Documentation**: [GitHub Wiki](https://github.com/rails-excel-reporter/rails-excel-reporter/wiki)
- **Changelog**: [CHANGELOG.md](https://github.com/rails-excel-reporter/rails-excel-reporter/blob/main/CHANGELOG.md)
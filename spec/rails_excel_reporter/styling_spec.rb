require 'spec_helper'

RSpec.describe RailsExcelReporter::Styling do
  let :styled_class do
    Class.new RailsExcelReporter::Base do
      attributes :id, :name, :email

      style :header, {
        bg_color: 'FF0000',
        fg_color: 'FFFFFF',
        bold: true
      }

      style :id, {
        alignment: { horizontal: :center }
      }

      style :name, {
        bold: true,
        font_size: 12
      }
    end
  end

  let :sample_data do
    [
      OpenStruct.new(id: 1, name: 'John', email: 'john@example.com'),
      OpenStruct.new(id: 2, name: 'Jane', email: 'jane@example.com')
    ]
  end

  let(:report) { styled_class.new sample_data }

  describe 'class methods' do
    describe '.style' do
      it 'defines styles for targets' do
        expect(styled_class.styles[:header]).to eq({
                                                     bg_color: 'FF0000',
                                                     fg_color: 'FFFFFF',
                                                     bold: true
                                                   })
      end

      it 'defines styles for columns' do
        expect(styled_class.styles[:id]).to eq({
                                                 alignment: { horizontal: :center }
                                               })
      end
    end

    describe '.styles' do
      it 'returns all defined styles' do
        expect(styled_class.styles).to include(:header, :id, :name)
      end
    end
  end

  describe 'instance methods' do
    describe '#get_header_style' do
      it 'returns merged header style with defaults' do
        header_style = report.get_header_style
        expect(header_style[:bg_color]).to eq('FF0000')
        expect(header_style[:bold]).to be true
      end
    end

    describe '#get_column_style' do
      it 'returns merged column style with defaults' do
        id_style = report.get_column_style :id
        expect(id_style[:alignment]).to eq({ horizontal: :center })
      end

      it 'returns default style for undefined columns' do
        email_style = report.get_column_style :email
        expect(email_style).to eq(RailsExcelReporter.config.default_styles[:cell])
      end
    end

    describe '#build_caxlsx_style' do
      it 'converts style options to caxlsx format' do
        style_options = {
          bg_color: 'FF0000',
          fg_color: 'FFFFFF',
          bold: true,
          font_size: 12,
          alignment: { horizontal: :center }
        }

        caxlsx_style = report.build_caxlsx_style style_options

        expect(caxlsx_style[:bg_color]).to eq('FF0000')
        expect(caxlsx_style[:fg_color]).to eq('FFFFFF')
        expect(caxlsx_style[:b]).to be true
        expect(caxlsx_style[:sz]).to eq(12)
        expect(caxlsx_style[:alignment]).to eq({ horizontal: :center })
      end
    end

    describe '#merge_styles' do
      it 'merges multiple styles' do
        styled_class.style :base, { bold: true, font_size: 10 }
        styled_class.style :override, { font_size: 12, italic: true }

        merged = report.merge_styles :base, :override

        expect(merged[:bold]).to be true
        expect(merged[:font_size]).to eq(12)
        expect(merged[:italic]).to be true
      end
    end
  end

  describe 'inheritance' do
    it 'inherits styles from parent class' do
      child_class = Class.new styled_class do
        style :email, { italic: true }
      end

      expect(child_class.styles).to include(:header, :id, :name, :email)
      expect(child_class.styles[:header][:bold]).to be true
      expect(child_class.styles[:email][:italic]).to be true
    end
  end
end

require 'open3'
require 'shellwords'

require 'pdfkit/adapters/base'
require 'pdfkit/adapters/url'
require 'pdfkit/adapters/html'
require 'pdfkit/adapters/file'
require 'pdfkit/html_option_parser'
require 'pdfkit/source'
require 'pdfkit/document'
require 'pdfkit/middleware'
require 'pdfkit/html_preprocessor'
require 'pdfkit/os'
require 'pdfkit/configuration'
require 'pdfkit/wkhtmltopdf'

module PDFKit
  class NoExecutableError < StandardError
    def initialize
      msg  = "No wkhtmltopdf executable found at #{PDFKit.configuration.wkhtmltopdf}\n"
      msg << ">> Please install wkhtmltopdf - https://github.com/pdfkit/PDFKit/wiki/Installing-WKHTMLTOPDF"
      super(msg)
    end
  end

  class ImproperSourceError < StandardError
    MESSAGE = 'Stylesheets may only be added to an HTML source'.freeze

    def initialize(msg = MESSAGE)
      super("Improper Source: #{msg}")
    end
  end

  class << self
    def new(*args)
      ensure_executable
      Document.new(*args)
    end

    private

    def ensure_executable
      return if File.exist?(PDFKit.configuration.wkhtmltopdf)
      raise NoExecutableError
    end
  end
end

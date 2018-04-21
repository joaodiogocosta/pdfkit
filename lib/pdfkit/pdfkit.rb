require 'shellwords'

class PDFKit
  extend Forwardable

  def_delegators :source, :adapter, :stylesheets, :stylesheets=
  def_delegators :renderer, :options

  attr_reader :renderer, :source

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

  attr_accessor :source

  def initialize(url_file_or_html, options = {})
    @source = Source.new(url_file_or_html, options)

    options = PDFKit.configuration.default_options.merge(options)
    options.delete(:quiet) if PDFKit.configuration.verbose?
    options.merge!(HtmlOptionParser.parse(url_file_or_html)) if source.parse_options?
    @renderer = WkHTMLtoPDF.new options
    @renderer.normalize_options
    ensure_executable
  end

  def ensure_executable
    return if File.exist?(PDFKit.configuration.wkhtmltopdf)
    raise NoExecutableError
  end

  def to_pdf(path = nil)
    @source.render(@renderer, path)
  end

  def command(path = nil)
    # FIXME: Just for tests to pass
    @renderer.command(@source, path)
  end

  def to_file(path)
    self.to_pdf(path)
    File.new(path)
  end
end

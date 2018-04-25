require 'shellwords'

module PDFKit
  class Document
    extend Forwardable

    def_delegators :source, :adapter, :stylesheets, :stylesheets=
    def_delegators :renderer, :options

    attr_reader :renderer, :source

    attr_accessor :source

    def initialize(url_file_or_html, options = {})
      @source = Source.new(url_file_or_html, options)
      options.merge!(HtmlOptionParser.parse(url_file_or_html)) if source.parse_options?
      @renderer = WkHTMLtoPDF.new(options)
    end

    def to_pdf(path = nil)
      source.render(renderer, path)
    end

    def command(path = nil)
      # FIXME: Just for tests to pass
      renderer.command(source, path)
    end

    def to_file(path)
      to_pdf(path)
      File.new(path)
    end
  end
end

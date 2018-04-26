module PDFKit
  class Document
    extend Forwardable

    attr_reader :source

    def_delegators :source, :adapter, :stylesheets, :stylesheets=, :<<

    module Legacy
      extend Forwardable

      def_delegators :source, :renderer

      def command(path = nil)
        renderer.command(path)
      end

      def options
        renderer.options
      end
    end
    include Legacy

    def initialize(*args)
      options = args.last.is_a?(::Hash) ? args.pop : {}
      @source = if args.any?
                  Source.new(args.first, options)
                else
                  Source.new(nil, options)
                end
    end

    def to_pdf(path = nil)
      source.renderer.output = path
      source.render
    end

    def to_file(path)
      to_pdf(path)
      File.new(path)
    end
  end
end

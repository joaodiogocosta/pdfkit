module PDFKit
  module Adapters
    class Abstract
      attr_reader :source, :options, :stylesheets, :output

      module Legacy
        def command(*args)
          renderer.command(*args)
        end
      end
      include Legacy

      def initialize(source, options = {})
        @source = source
        @options = options
        @stylesheets = []
        @output = options[:output]
      end

      def renderer
        @renderer ||= build_renderer(options)
      end

      def render
        preprocess
        renderer.execute
      end

      def to_input_for_command
        raise NotImplementedError
      end

      def to_s
        raise NotImplementedError
      end

      def parse_options?
        raise NotImplementedError
      end

      def preprocess
        return unless stylesheets.any?
        raise PDFKit::ImproperSourceError
      end

      protected

      attr_writer :source

      def build_renderer(opts = {})
        WkHTMLtoPDF.new(
          to_input_for_command,
          output,
          opts
        )
      end
    end
  end
end

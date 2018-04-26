module PDFKit
  module Adapters
    class Html < Abstract
      SOURCE_FROM_STDIN = '-'.freeze

      def renderer
        return @renderer if @renderer
        html_opts = HtmlOptionParser.parse(to_s)
        renderer_opts = options.merge(html_opts)
        @renderer = build_renderer(renderer_opts)
      end

      def to_input_for_command
        SOURCE_FROM_STDIN
      end

      def to_s
        source
      end

      def preprocess
        preprocess_html
        append_stylesheets if stylesheets.any?
      end

      def render
        preprocess
        renderer << source
        renderer.execute
      end

      private

      def preprocess_html
        # TODO: Process in streaming!
        processed_html = PDFKit::HTMLPreprocessor.process(
          source,
          options[:root_url],
          options[:protocol]
        )
        self.source = processed_html
      end

      def append_stylesheets
        if source.match(/<\/head>/)
          self.source = source.gsub(/(<\/head>)/) do |s|
            html_for_stylesheets + s
          end
        else
          source.insert(0, html_for_stylesheets)
        end
      end

      def html_for_stylesheets
        stylesheets.map do |stylesheet|
          style_tag_for(stylesheet)
        end.join('')
      end

      def style_tag_for(stylesheet)
        "<style>#{::File.read(stylesheet)}</style>"
      end
    end
  end
end

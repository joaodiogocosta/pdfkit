module Adapters
  class Html < Abstract
    SOURCE_FROM_STDIN = '-'.freeze

    def initialize(*args)
      super(*args)
    end

    def to_input_for_command
      SOURCE_FROM_STDIN
    end

    def to_s
      source
    end

    def parse_options?
      true
    end

    def preprocess
      preprocess_html
      append_stylesheets
    end

    def render(renderer, path = nil)
      super do |pdf|
        pdf.puts(to_s)
      end
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
      stylesheets.each do |stylesheet|
        if source.to_s.match(/<\/head>/)
          self.source = source.to_s.gsub(/(<\/head>)/) {|s| style_tag_for(stylesheet) + s }
        else
          source.to_s.insert(0, style_tag_for(stylesheet))
        end
      end
    end

    def style_tag_for(stylesheet)
      "<style>#{::File.read(stylesheet)}</style>"
    end
  end
end

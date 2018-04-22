require 'uri'

module PDFKit
  class Source
    extend Forwardable

    attr_reader :adapter

    def_delegators :adapter,
      :to_input_for_command,
      :to_s,
      :parse_options?,
      :preprocess,
      :stylesheets,
      :stylesheets=,
      :render

    def initialize(raw_source, options = {})
      adapter_klass = find_adapter(raw_source)
      @adapter = adapter_klass.new(raw_source, options)
    end

    private

    def find_adapter(raw_source)
      if file?(raw_source)
        Adapters::File
      elsif url?(raw_source)
        Adapters::Url
      elsif html?(raw_source)
        Adapters::Html
      else
        raise 'Not Supported'
      end
    end

    def file?(raw_source)
      raw_source.is_a?(File) || raw_source.is_a?(Tempfile)
    end

    def url?(raw_source)
      raw_source.is_a?(String) && raw_source.match(/\Ahttp/)
    end

    def html?(raw_source)
      raw_source.is_a?(String) && !url?(raw_source)
    end
  end
end

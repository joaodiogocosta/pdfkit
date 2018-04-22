module Adapters
  class Base
    attr_reader :source, :options, :stylesheets

    def initialize(source, options = {})
      @source = source
      @options = options
      @stylesheets = []
    end

    def render(renderer, path = nil)
      preprocess
      renderer.execute(self, path) do |pdf|
        yield pdf if block_given?
      end
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
  end
end

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

      invoke = renderer.command(self, path)

      result = IO.popen(invoke, 'wb+') do |pdf|
        yield pdf if block_given?
        pdf.close_write
        pdf.gets(nil) if path.nil?
      end

      # $? is thread safe per
      # http://stackoverflow.com/questions/2164887/thread-safe-external-process-in-ruby-plus-checking-exitstatus
      if empty_result?(path, result) || !successful?($?)
        raise "command failed (exitstatus=#{$?.exitstatus}): #{invoke}"
      end
      result
    end

    def empty_result?(path, result)
      (path && ::File.size(path) == 0) || (path.nil? && result.to_s.strip.empty?)
    end

    def successful?(status)
      return true if status.success?

      # Some of the codes: https://code.google.com/p/wkhtmltopdf/issues/detail?id=1088
      # returned when assets are missing (404): https://code.google.com/p/wkhtmltopdf/issues/detail?id=548
      return true if status.exitstatus == 2 && @renderer.error_handling?

      false
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

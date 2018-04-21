module Adapters
  class Url < Base
    PREPROCESS_ERROR_MESSAGE = 'Stylesheets may only be added to an HTML source'.freeze
    def to_input_for_command
      %{"#{shell_safe_url}"}
    end

    def to_s
      source.dup
    end

    def parse_options?
      false
    end

    private

    def shell_safe_url
      if url_needs_escaping?
        URI.escape(source)
      else
        source
      end
    end

    def url_needs_escaping?
      URI.decode(source) == source
    end
  end
end

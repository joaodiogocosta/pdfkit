module PDFKit
  module Adapters
    class File < Abstract
      def to_input_for_command
        source.path
      end

      def to_s
        source.path
      end

      def parse_options?
        true
      end
    end
  end
end

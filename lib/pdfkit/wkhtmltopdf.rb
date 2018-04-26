module PDFKit
  class WkHTMLtoPDF
    attr_reader :input_for_command, :options
    attr_accessor :output

    WkProcess = Struct.new(:stdin, :stdout, :wait_thread)

    # Pulled from:
    # https://github.com/wkhtmltopdf/wkhtmltopdf/blob/ebf9b6cfc4c58a31349fb94c568b254fac37b3d3/README_WKHTMLTOIMAGE#L27
    REPEATABLE_OPTIONS = %w[--allow --cookie --custom-header --post --post-file --run-script]
    SPECIAL_OPTIONS = %w[cover toc]

    def initialize(input_for_command, output, options = {})
      @input_for_command = input_for_command
      @output = output
      @options = build_options(options)
      normalize_options
      @process = nil
    end

    def <<(chunk)
      process.stdin << chunk
    end

    def process
      return @process if @process
      stdin, stdout, th = Open3.popen2(command)
      stdout.binmode
      @process = WkProcess.new(stdin, stdout, th)
    end

    def reset_process
      @process = nil
    end

    def execute
      process.stdin.close_write
      result = process.stdout.gets(nil) if output.nil?
      process.stdout.close
      process_status = process.wait_thread.value
      if empty_result?(output, result) || !successful?(process_status)
        raise "command failed (exitstatus=#{process_status.exitstatus}): #{command}"
      end
      result
    ensure
      process.stdin.close
      process.stdout.close
      process.wait_thread.kill
      reset_process
    end

    def normalize_options
      # TODO(cdwort,sigmavirus24): Make this method idempotent in a future release so it can be called repeatedly
      normalized_options = {}

      @options.each do |key, value|
        next if !value

        # The actual option for wkhtmltopdf
        normalized_key = normalize_arg key
        normalized_key = "--#{normalized_key}" unless SPECIAL_OPTIONS.include?(normalized_key)

        # If the option is repeatable, attempt to normalize all values
        if REPEATABLE_OPTIONS.include? normalized_key
          normalize_repeatable_value(normalized_key, value) do |normalized_unique_key, normalized_value|
            normalized_options[normalized_unique_key] = normalized_value
          end
        else # Otherwise, just normalize it like usual
          normalized_options[normalized_key] = normalize_value(value)
        end
      end

      @options = normalized_options
    end

    def error_handling?
      @options.key?('--ignore-load-errors') ||
        # wkhtmltopdf v0.10.0 beta4 replaces ignore-load-errors with load-error-handling
        # https://code.google.com/p/wkhtmltopdf/issues/detail?id=55
        %w(skip ignore).include?(@options['--load-error-handling'])
    end

    def options_for_command
      @options.to_a.flatten.compact
    end

    def command(path = nil)
      path = path || output
      args = options_for_command
      shell_escaped_command = [executable, OS::shell_escape_for_os(args)].join ' '

      # In order to allow for URL parameters (e.g. https://www.google.com/search?q=pdfkit) we do
      # not escape the source. The user is responsible for ensuring that no vulnerabilities exist
      # in the source. Please see https://github.com/pdfkit/pdfkit/issues/164.
      output_for_command = path ? Shellwords.shellescape(path) : '-'

      "#{shell_escaped_command} #{input_for_command} #{output_for_command}"
    end

    private

    def executable
      PDFKit.configuration.wkhtmltopdf
    end

    def normalize_arg(arg)
      arg.to_s.downcase.gsub(/[^a-z0-9]/,'-')
    end

    def normalize_value(value)
      case value
      when nil
        nil
      when TrueClass, 'true' #ie, ==true, see http://www.ruby-doc.org/core-1.9.3/TrueClass.html
        nil
      when Hash
        value.to_a.flatten.collect{|x| normalize_value(x)}.compact
      when Array
        value.flatten.collect{|x| x.to_s}
      else
        (OS::host_is_windows? && value.to_s.index(' ')) ? "'#{ value.to_s }'" : value.to_s
      end
    end

    def normalize_repeatable_value(option_name, value)
      case value
      when Hash, Array
        value.each do |(key, val)|
          yield [[option_name, normalize_value(key)], normalize_value(val)]
        end
      else
        yield [[option_name, normalize_value(value)], nil]
      end
    end

    def build_options(options)
      options = PDFKit.configuration.default_options.merge(options)
      options.delete(:quiet) if PDFKit.configuration.verbose?
      censor(options)
    end

    def censor(opts)
      new_options = opts.dup
      new_options.delete(:root_url)
      new_options.delete(:protocol)
      new_options
    end

    def empty_result?(output, result)
      (output && ::File.size(output) == 0) || (output.nil? && result.to_s.strip.empty?)
    end

    def successful?(status)
      # Some of the codes: https://code.google.com/p/wkhtmltopdf/issues/detail?id=1088
      # returned when assets are missing (404): https://code.google.com/p/wkhtmltopdf/issues/detail?id=548
      if status.success? || (status.exitstatus == 2 && @renderer.error_handling?)
        true
      else
        false
      end
    end
  end
end

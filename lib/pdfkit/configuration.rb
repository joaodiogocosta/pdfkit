module PDFKit
  class Configuration
    attr_accessor :meta_tag_prefix, :default_options, :root_url
    attr_writer :verbose

    def initialize
      @verbose = false
      @meta_tag_prefix = 'pdfkit-'
      @default_options = build_default_options
    end

    def wkhtmltopdf
      @wkhtmltopdf ||= default_wkhtmltopdf
    end

    def wkhtmltopdf=(path)
      if File.exist?(path)
        @wkhtmltopdf = path
      else
        warn "No executable found at #{path}. Will fall back to #{default_wkhtmltopdf}"
        @wkhtmltopdf = default_wkhtmltopdf
      end
    end

    def default_wkhtmltopdf
      return @default_command_path if @default_command_path
      gemfile = defined?(Bundler::GemfileError) && File.exist?('Gemfile')
      command = 'which wkhtmltopdf'
      @default_command_path = gemfile ? `bundle exec #{command}` : `#{command}`
      @default_command_path.chomp!
    end

    def quiet?
      !@verbose
    end

    def verbose?
      @verbose
    end

    def build_default_options
      {
        disable_smart_shrinking: false,
        quiet: true,
        page_size: 'Letter',
        margin_top: '0.75in',
        margin_right: '0.75in',
        margin_bottom: '0.75in',
        margin_left: '0.75in',
        encoding: 'UTF-8'
      }
    end
  end

  class << self
    attr_accessor :configuration
  end

  # Configure PDFKit someplace sensible,
  # like config/initializers/pdfkit.rb
  #
  # @example
  #   PDFKit.configure do |config|
  #     config.wkhtmltopdf = '/usr/bin/wkhtmltopdf'
  #     config.verbose     = true
  #   end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end

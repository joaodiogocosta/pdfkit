require 'rbconfig'

module PDFKit
  module OS
    extend self

    def host_is_windows?
      !(RbConfig::CONFIG['host_os'] =~ /mswin|msys|mingw|cygwin|bccwin|wince/).nil?
    end

    def shell_escape_for_os(args)
      if (host_is_windows?)
        # Windows reserved shell characters are: & | ( ) < > ^
        # See http://technet.microsoft.com/en-us/library/cc723564.aspx#XSLTsection123121120120
        args.map { |arg| arg.gsub(/([&|()<>^])/,'^\1') }.join(" ")
      else
        args.shelljoin
      end
    end
  end
end

module PDFKit
  module HtmlOptionParser
    extend self

    def parse(content)
      # Read file if content is a File
      # TODO: Do through streaming
      content = content.read if content.is_a?(File)

      found = {}
      content.scan(/<meta [^>]*>/) do |meta|
        if meta.match(/name=["']#{PDFKit.configuration.meta_tag_prefix}/)
          name = meta.scan(/name=["']#{PDFKit.configuration.meta_tag_prefix}([^"']*)/)[0][0].split
          found[name] = meta.scan(/content=["']([^"'\\]+)["']/)[0][0]
        end
      end

      tuple_keys = found.keys.select { |k| k.is_a? Array }
      tuple_keys.each do |key|
        value = found.delete key
        new_key = key.shift
        found[new_key] ||= {}
        found[new_key][key] = value
      end

      found
    end
  end
end

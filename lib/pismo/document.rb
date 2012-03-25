require 'pismo/internal_attributes'
require 'pismo/external_attributes'

module Pismo
  
  # Pismo::Document represents a single HTML document within Pismo
  class Document
  
    attr_reader :doc, :url, :options
    
    ATTRIBUTE_METHODS = InternalAttributes.instance_methods + ExternalAttributes.instance_methods
    
    include Pismo::InternalAttributes
    include Pismo::ExternalAttributes
    
    def initialize(handle, options = {})
      @options = options
      url = @options.delete(:url)
      load(handle, url)
    end
    
    # An HTML representation of the document
    def html
      @doc.to_s
    end
    
    def load(handle, url = nil)
      @url = url if url
      @url = handle if handle =~ /\Ahttp/i
      
      @html = if handle =~ /\Ahttp/i
                open(handle).read
              elsif handle.is_a?(StringIO) || handle.is_a?(IO) || handle.is_a?(Tempfile)
                handle.read
              else
                handle
              end

      @html = self.class.handle_content_encoding(@html)        
      @html = self.class.clean_html(@html)
      
      @doc = Nokogiri::HTML(@html)
    end
    
    def match(args = [], all = false)
      @doc.match([*args], all)
    end
    
    def self.handle_content_encoding(html)
        # Ruby version is greater than 1.9, so use the native
        # String.encoding method of handling unicode
        # TODO: Handle < 1.9 with Iconv --  Wed Feb 29 15:24:18 2012
        if RUBY_VERSION > "1.9"
          # If the raw content is marked as UTF-8 and is not valid,
          # clean it up by replacing invalidly encoded chars with '?',
          # otherwise if the encoding is not UTF-8, try to force the
          # conversion and if that fails try to force the content into ASCII-8BIT
          if html.encoding == 'UTF-8' && html.valid_encoding? == false
             html.encode!("UTF-8", :invalid => :replace, :undef => :replace, :replace => '?')
          elsif html.encoding != 'UTF-8'
            html.encode!("UTF-8", :invalid => :replace, :undef => :replace, :replace => '?')
            html.encode!("ASCII-8BIT", :invalid => :replace, :undef => :replace, :replace => '?') if !html.valid_encoding?
          end
        end
        html
    end

    def self.clean_html(html)
      # Normalize stupid entities
      # TODO: Optimize this so we don't need all these sequential gsubs
      html.gsub!("&#8194;", " ")
      html.gsub!("&#8195;", " ")
      html.gsub!("&#8201;", " ")
      html.gsub!('&#8211;', '-')
      html.gsub!("&#8216;", "'")
      html.gsub!('&#8217;', "'")
      html.gsub!('&#8220;', '"')
      html.gsub!('&#8221;', '"')
      html.gsub!("&#8230;", '...')
      html.gsub!('&nbsp;', ' ')
      html.gsub!('&lt;', '<')
      html.gsub!('&gt;', '>')
      html.gsub!('&amp;', '&')
      html
    end
  end
end

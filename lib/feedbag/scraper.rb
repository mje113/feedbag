require 'open-uri'
require 'nokogiri'

module Feedbag
  class Scraper

    attr_accessor :content_type

    def initialize(url)
      @url = url
    end

    def content_type
      @content_type ||= begin
        ct = response.content_type.downcase
        if ct == "application/octet-stream" # open failed
          response.meta["content-type"].gsub(/;.*$/, '')
        else
          ct
        end
      end
    end

    def doc
      @doc ||= Nokogiri::HTML(response.read)
    end

    private

    def response
      @response ||= open(@url)

    # gotta be a better way of handling
    rescue Timeout::Error => err
      $stderr.puts "Timeout error ocurred with `#{url}: #{err}'"
    rescue OpenURI::HTTPError => the_error
      $stderr.puts "Error ocurred with `#{url}': #{the_error}"
    rescue SocketError => err
      $stderr.puts "Socket error ocurred with: `#{url}': #{err}"
    end
  end
end

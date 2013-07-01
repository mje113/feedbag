require 'thread'
require 'pry'

module Feedbag
  class Spider

    def initialize(url)
      @url   = url
      @mutex = Mutex.new
    end

    def find
      finder = Finder.new(@url)
      feeds =  finder.find
      return feeds unless feeds.empty?

      doc   = finder.scraper.doc
      links = doc.css('a').map { |l| l['href'] }.compact.uniq
      links = links.select { |l| l != @url }

      threads = []
      links.each do |link|
        puts absolute_url(link)
        threads << Thread.new do |thread|
          new_feeds = Finder.new(absolute_url(link)).find
          @mutex.synchronize do
            feeds += new_feeds
          end
        end
      end

      threads.map(&:join)
      feeds
    end

    private

    def absolute_url(url)
      uri = URI.parse(url)
      uri.host.nil? ? "#{base_uri}#{url}" : url
    end

    def base_uri
      uri = URI.parse(@url)
      "#{uri.scheme}://#{uri.host}"
    end
  end
end

def OpenURI.redirectable?(uri1, uri2) # :nodoc:
  # This test is intended to forbid a redirection from http://... to
  # file:///etc/passwd.
  # However this is ad hoc.  It should be extensible/configurable.
  uri1.scheme.downcase == uri2.scheme.downcase ||
  (/\A(?:https|http|ftp)\z/i =~ uri1.scheme && /\A(?:https|http|ftp)\z/i =~ uri2.scheme)
end

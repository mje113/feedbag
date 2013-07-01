module Feedbag
  class Finder

    CONTENT_TYPES = [
      'application/x.atom+xml',
      'application/atom+xml',
      'application/xml',
      'text/xml',
      'application/rss+xml',
      'application/rdf+xml',
    ].freeze

    attr_accessor :scraper

    def initialize(url = nil)
      @url     = parse_url(url)
      @feeds   = Set.new
      @scraper = Scraper.new(@url)
    end

    def feed?
      # hack:
      url = @url.sub(/^feed:\/\//, 'http://')
  
      res = Feedbag.find(url)
      res.size == 1 && res.first == url
    end

    def find
      if feed_scheme?
        add_feed(@uri.to_s.sub(/^feed:\/\//, 'http://'), nil)
      elsif w3c_valid? || feed_content_type?
        add_feed(@url, nil)
      else
        add_from_scraper
      end

      @feeds.to_a
    end

    protected

    def parse_url(url)
      @uri = URI.parse(url)
      if @uri.scheme.nil?
        "http://#{url_uri.to_s}"
      else
        @uri.to_s
      end
    end

    def add_from_scraper
      doc = @scraper.doc
  
      if doc.at("base") && doc.at("base")["href"]
        base_uri = doc.at("base")["href"]
      else
        base_uri = nil
      end
  
      # first with links
      (doc/"atom:link").each do |l|
        next unless l["rel"]
        if l["type"] && feed_content_type?(l["type"].downcase.strip) && l["rel"].downcase == "self"
          add_feed(l["href"], @url, base_uri)
        end
      end
  
      (doc/"link").each do |l|
        next unless l["rel"]
        if l["type"] && feed_content_type?(l["type"].downcase.strip) && (l["rel"].downcase =~ /alternate/i || l["rel"] == "service.feed")
          add_feed(l["href"], @url, base_uri)
        end
      end
  
      (doc/"a").each do |a|
        next unless a["href"]
        if looks_like_feed?(a["href"]) && (a["href"] =~ /\// || a["href"] =~ /#{url_uri.host}/)
          add_feed(a["href"], @url, base_uri)
        end
      end
  
      (doc/"a").each do |a|
        next unless a["href"]
        if looks_like_feed?(a["href"])
          add_feed(a["href"], @url, base_uri)
        end
      end

      # Added support for feeds like http://tabtimes.com/tbfeed/mashable/full.xml
      if @url.match(/.xml$/) && doc.root && doc.root["xml:base"] && doc.root["xml:base"].strip == url.strip
        add_feed(@url, nil)
      end
    end
  
    def looks_like_feed?(url)
      url =~ /(\.(rdf|xml|rdf|rss)$|feed=(rss|atom)|(atom|feed)\/?$)/i
    end
  
    def add_feed(feed_url, orig_url, base_uri = nil)
      # puts "#{feed_url} - #{orig_url}"
      url = feed_url.sub(/^feed:/, '').strip
  
      if base_uri
        # url = base_uri + feed_url
        url = URI.parse(base_uri).merge(feed_url).to_s
      end
  
      begin
        uri = URI.parse(url)
      rescue
        puts "Error with `#{url}'"
        exit 1
      end
      unless uri.absolute?
        orig = URI.parse(orig_url)
        url = orig.merge(url).to_s
      end
  
      # feeds is a Set, no need for dupe checking
      @feeds << url
    end

    def feed_content_type?(content_type = @scraper.content_type)
      CONTENT_TYPES.include?(content_type)
    end

    def feed_scheme?
      @uri.scheme == 'feed'
    end

    def w3c_valid?
      # Can't see how this block of code was working correctly in its original location
      begin
        require 'feed_validator'
        v = W3C::FeedValidator.new
        v.validate_url(@url).valid?
      rescue LoadError
        # Just assume it's not valid
        false
      rescue REXML::ParseException
        # usually indicates timeout
        # TODO: actually find out timeout. use Terminator?
        # $stderr.puts "Feed looked like feed but might not have passed validation or timed out"
        false
      rescue => ex
        $stderr.puts "#{ex.class} error ocurred with: `#{url}': #{ex.message}"
        false
      end
    end
  
    # not used. yet.
    def _is_http_valid(uri, orig_url)
      req = Net::HTTP.get_response(uri)
      orig_uri = URI.parse(orig_url)
      case req
        when Net::HTTPSuccess then
          return true
        else
          return false
      end
    end
  end
end
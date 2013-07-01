#!/usr/bin/ruby

# Copyright (c) 2012 David Moreno <david@axiombox.com>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'rubygems'
require 'net/http'
require 'feedbag/finder'
require 'feedbag/scraper'
require 'feedbag/spider'

module Feedbag

  def self.feed?(url)
    Finder.new(url).feed?
  end

  def self.find(url)
    Finder.new(url).find
  end

  def self.spider(url)
    Spider.new(url).find
  end
  
end

if __FILE__ == $0
  if ARGV.size == 0
    puts 'usage: feedbag url'
  else
    puts Feedbag.find ARGV.first
  end
end

#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'pry'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('.uk-overlay').each do |mp|
    box = mp.css('.uk-overlay-area-content')
    data = { 
      name: box.xpath('p/text()').text.sub('Hon. ','').tidy,
      area: box.xpath('p/small').text.split('|').last.tidy,
      image: mp.css('img/@src').text,
      term: 2012,
      source: box.css('p a/@href').text,
    }
    data[:image] = URI.join(url, data[:image]).to_s unless data[:image].to_s.empty?
    data[:source] = data[:source].to_s.empty? ? url : URI.join(url, data[:source]).to_s 
    ScraperWiki.save_sqlite([:name, :term], data)
  end
end

scrape_list('https://www.gov.tc/index.php/government/house-of-assembly')

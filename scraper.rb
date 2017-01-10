#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

class MembersList < Scraped::HTML
  decorator Scraped::Response::Decorator::AbsoluteUrls

  field :members do
    noko.css('.uk-overlay').map do |mp|
      fragment mp => MemberBox
    end
  end
end

class MemberBox < Scraped::HTML
  field :name do
    box.xpath('p/text()').text.sub('Hon. ', '').tidy
  end

  field :area do
    box.xpath('p/small').text.split('|').last.tidy
  end

  field :image do
    noko.css('img/@src').text
  end

  field :source do
    box.css('p a/@href').text
  end

  private

  def box
    noko.css('.uk-overlay-area-content')
  end
end

url = 'https://www.gov.tc/index.php/government/house-of-assembly'
page = MembersList.new(response: Scraped::Request.new(url: url).response)
data = page.members.map(&:to_h).each do |mem|
  # Not all members have individual links
  mem[:source] = url if mem[:source].to_s.empty?
end

# puts data

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
ScraperWiki.save_sqlite(%i(name area), data)

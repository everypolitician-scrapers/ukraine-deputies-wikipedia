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

def date_from(text)
  return if text.to_s.empty?
  Date.parse(text).to_s rescue binding.pry
end

def scrape_list(url)
  noko = noko_for(url)
  constituency = ''

  noko.xpath('//table[contains(caption,"Народні депутати VIII скликання")]//tr[td]').each do |tr|
    tds = tr.css('td')
    data = { 
      name: tds[2].text,
      wikiname: tds[2].xpath('.//a[not(@class="new")]/@title').text,
      party: tds[1].text.tidy,
      list_number: tds[3].text.tidy,
      area_id: tds[4].text.tidy,
      faction: tds[5].text.tidy,
      term: 8,
      start_date: date_from(tds[6].text)
    }
    # puts data
    # Let's assume there aren't two people in the same party with the same name
    ScraperWiki.save_sqlite([:name, :party, :term], data)
  end

  noko.xpath('//h3[contains(span,"Депутати, що вибули")]/following-sibling::table[1]/tr[td]').each do |tr|
    tds = tr.css('td')
    data = { 
      name: tds[2].text,
      wikiname: tds[2].xpath('.//a[not(@class="new")]/@title').text,
      party: tds[1].text.tidy,
      list_number: tds[3].text.tidy,
      area_id: tds[4].text.tidy,
      term: 8,
      end_date: date_from(tds[5].text)
    }
    # puts data
    ScraperWiki.save_sqlite([:name, :party, :term], data)
  end

end

scrape_list('https://uk.wikipedia.org/wiki/%D0%92%D0%B5%D1%80%D1%85%D0%BE%D0%B2%D0%BD%D0%B0_%D0%A0%D0%B0%D0%B4%D0%B0_%D0%A3%D0%BA%D1%80%D0%B0%D1%97%D0%BD%D0%B8_VIII_%D1%81%D0%BA%D0%BB%D0%B8%D0%BA%D0%B0%D0%BD%D0%BD%D1%8F')

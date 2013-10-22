#!/usr/bin/ruby -w
#encoding: UTF-8

$LOAD_PATH << File.dirname(__FILE__)

require 'FastKanji.rb'
require 'UnicodeSupport.rb'

$kanji_data = nil
$kanji_by_keyword = {} # hash of keyword (as symbol) to kanji unicode

def find_kanji_unicode_from_keyword(keyword)
  k = KD.instance().kanji()[keyword]
  return k.nil?() ? nil : k.unicode()
end

def convert_to_kanji(text)
  kanji = {
    :hon => 0x672c, :watashi => 0x79c1,
    :chiga => 0x9055, :i => 0x884c,
    :ku => 0x6765, # reconsider
    :rai => 0x6765, # also ku
    :kae => 0x5e30, # reconsider
    :samui => 0x5bd2,
    :arinashi => 0x6709, # possess
    :namae => 0x540d, :utsuru => 0x6620,
    :yonkaku => 0x753b, # check
    :ookii => 0x5927,
    :manabu => 0x5b66,
    :ichi => 0x4e00, :ni => 0x4e8c, :san => 0x4e09, :yon => 0x56db, :go => 0x4e94,
    :roku => 0x516d, :nana => 0x4e03, :hachi => 0x516b, :kyuu => 0x4e5d, :juu => 0x5341,
    :dan => 0x6bb5,
    :kai => 0x4f1a,
    :kou => 0x884c,
    :shoku => 0x98df,
    :mi => 0x898b,
    :noma => 0x3005, # repetition symbol
    :yuubin => 0x3012, # indicates Japanese post office on a map
    :jisuma => 0x3004, # shows that a product complies with a Japanese Industrial Standard
    :maruhi => 3299, # "secret"
  }

  text.gsub!(/['a-zA-Z.*-]+/).each() {
    |word|
    result = ""
    code = kanji[word.downcase().to_sym()]
    code = find_kanji_unicode_from_keyword(word.downcase()) if code.nil?()
    if code.nil?()
      result += "&lt;UNKNOWN KANJI [#{word}]&gt;"
    else
      result += jp_unicode(code)
    end
    result
  }
  return text.gsub("^", "")
end

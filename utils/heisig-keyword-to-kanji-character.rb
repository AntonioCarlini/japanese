#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

$LOAD_PATH << File.dirname(__FILE__)
$LOAD_PATH << File.dirname(__FILE__).sub(/\.$/, "../scripts").sub(/utils$/, "scripts")

require 'KanjiSupport.rb'

ARGV.each() {
  |keyword|
  u = find_kanji_unicode_from_keyword(keyword)
  c = [ u ].pack("U*")
  print "#{c}"
}
puts()

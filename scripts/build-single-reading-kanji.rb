#!/usr/bin/ruby -w
#encoding: UTF-8

$LOAD_PATH << File.dirname(__FILE__)

require 'DataKanjidic.rb'

# Add <=> to Kanji type so that sort() can be used.
class Kanji
  def <=>(other)
    return -1 if other.nil?()
    sg = self.grade()
    og = other.grade()
    sg = 100 if sg.nil?()
    og = 100 if og.nil?()
    r = sg <=> og
    return (r != 0) ? r : @heisig <=> other.heisig()
  end
end
    
# ARGV[0] - kanjidic
kanjidic = ARGV.shift()

all_kanji = DataKanjidic.create_from_file(kanjidic)

# Try to select a unique reading => kanji mapping for each kanji
# Start by building a hash of reading => array of kanji
# Ignore nanori.
readings = Hash.new() { |hash, key| hash[key] = [] }

all_kanji.keys().sort().each() {
  |key|
  k = all_kanji[key]
  (k.onyomi() + k.kunyomi()).each() {
    |r|
    readings[r] << k
  }
}

# Now find all unique readings and list each of these
readings.keys().sort().each() {
  |r|
  readings[r].first().add_reading(r) if readings[r].size() == 1
}

array_of_1r_kanji = []
all_kanji.keys().sort().each() {
  |key|
  k = all_kanji[key]
  array_of_1r_kanji << k if (k.onyomi().size() + k.kunyomi().size()) == 1
}

# Sort the array by grade and then by Heisig index and display the results in a form
# suitable for inclusion in a (specific) web page.

puts(" <tr>")
puts("   <th> Kanji </th>")
puts("   <th> Heisig# </th>")
puts("   <th> Grade </th>")
puts("   <th> Reading </th>")
puts("   <th> Meaning </th>")
puts(" </tr>")
puts("array_of_1r_kanji.class array_of_1r_kanji.first.class")
array_of_1r_kanji.sort().each() {
  |k|
  op = ""
  op << " <tr>\n"
  op << "   <td> &#x%4.4x </td>" % k.unicode()
  op << " <td> %5d </td>" % k.heisig()
  if k.grade().nil?()
    op << " <td> &nbsp; </td>"
  else
    op << " <td> %3d </td>" % k.grade()
  end
  op << " <td>"
  op << " @HI{{#{k.kunyomi().first()}}} </td>" unless k.kunyomi().empty?()
  op << " @KT{{#{k.onyomi().first()}}} </td>" unless k.onyomi().empty?()
  op << "</td>\n"
  meanings = k.english().gsub(/} \s+ {/ix, ",")
  op << "   <td> " <<  meanings.gsub(/{|}/, "") << " </td>\n"
  op << " </tr>\n"
  puts(op)
}

#!/usr/bin/ruby -w
#encoding: utf-8

$LOAD_PATH << File.dirname(__FILE__)

#+
# Reads in the kanji data and produces a list of Hesig kanji by index.
# The resulting file should be processed to convert the @KJ{{}} codes to unicode.
# Doing so will show up any kanji that cannot be accessed by keyword, as well as providing
# a useful reference.
#-

require 'DataKanji.rb'

# Read the Heisig kanji data file (supplied as first argument)
kanji_data_file = ARGV.shift()
kanji_data = DataKanji.create_from_file(kanji_data_file)

heisig = []  # list of kanji indexed by Heisg number

# Build an array of kanji by Heisig index
kanji = kanji_data.kanji()
kanji.each() {
  |obj|
  h = obj.heisig()
  raise("Saw ##{h} more than once.") unless heisig[h].nil?()
  heisig[h] = obj
}

# Walk the Hesig kanji list, writing out kanji data in HTML　table format.
# Complain (at the end) if any kanji were missing.
puts("<!DOCTYPE html>")
puts("<html>")
puts("<head>")
puts("<title>Kanji By Heisig Number</title>")
puts("<link rel=\"stylesheet\" type=\"text/css\" href=\"japanese.css\"/>")
puts("<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">")
puts("</head>")
puts("<body>")
puts()
puts("<h1>Kanji By Heisig Number</h1>")
puts()
puts('<table class="example">')
print('<tr> ')
print('<th>　Heisig </th>')
print('<th>　Kanji </th>')
print('<th>　Keyword </th>')
print('<th> @KT{{onnyomi}}  </th>')
#print('<th> @HI{{kunnyomi}} </th>')
print('<th>　JLPT </th>')
print('<th>　@KJ{{usual^utilize}} </th>')
puts('</tr>')

1.upto(2042) {
  |h|
  keyword = heisig[h].english()[0]
  mangled_keyword = heisig[h].english()[0].gsub(' ', '*')
  print('<tr> ')
  print("<td> #{h} </td>")
  print("<td> @KJ{{#{mangled_keyword}}} </td>")
  print("<td> #{keyword} </td>")
  print("<td> #{heisig[h].onyomi().join(',')} </td>")
#  print("<td> #{heisig[h].kunyomi().join(',')} </td>")
  print("<td> #{heisig[h].jlpt()} </td>")
  print("<td> #{heisig[h].jouyou()} </td>")
  puts('</tr>')
}

puts('</table>')
puts('</body>')
puts('</html>')

#!/usr/bin/ruby -w
#encoding: UTF-8

$LOAD_PATH << File.dirname(__FILE__)

require 'RadicalSupport.rb'

#+
# Loads the radical data and produces a table of radicals
#-

TITLE = "Kanji Radicals"

puts("<!DOCTYPE html>")
puts("<html>")
puts("<head>")
puts("<title>#{TITLE}</title>")
puts("<link rel=\"stylesheet\" type=\"text/css\" href=\"japanese.css\"/>")
puts("<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">")
puts("</head>")
puts("<body>")
puts()
puts("<h1>#{TITLE}</h1>")
puts()
puts('<table class="example">')
print('<tr> ')
print('<th>　Name </th>')
print('<th>　Reading </th>')
print('<th>　Unicode </th>')
print('<th> Radical </th>')
puts('</tr>')

# Work through the container of Radicals.
# Mark as BAD any where the key and the radical english() entry do not match.
# Count the radicals so that it is easy to see iof any are missing.
count = 0
RD.instance().radical().each() {
  |key,radical|
  count += 1
  print('<tr> ')
  key_bad = (key != radical.english()) ? "BAD" : ""
  print("<td> #{key} #{key_bad}</td>")
  print("<td> @HI{{#{radical.reading()}}} </td>")
  print("<td> #{radical.unicode()} </td>")
  print("<td> @RD{{#{key}}} </td>")
  puts('</tr>')
}

puts('</table>')
puts("<p>#{count} radicals displayed.</p>")
puts('</body>')
puts('</html>')

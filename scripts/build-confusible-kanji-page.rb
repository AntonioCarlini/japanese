#!/usr/bin/env ruby
# frozen_string_literal: true

# 7-bit clean HTML generator for confusible kanji table.

abort("usage: #{$0} <kanji.data> <confusible-kanji.txt>") unless ARGV.length() == 2

kanji_data_path = ARGV[0]
confusible_path = ARGV[1]

require_relative("DataKanji.rb")

#
# Helpers
#

def trim(s)
  return(s.strip())
end

def keyword_to_kj(keyword)
  # spaces must become '*'
  return("@KJ{{#{keyword.gsub(" ", "*")}}}")
end

def parse_line(line)
  line = trim(line)
#  return(nil) if line.empty()
#  return(nil) if line.start_with?("#")

  parts = line.split(",").map { |x| trim(x) }
  return(parts)
end

#
# Load kanji data (only for validation if available)
#

kanji_db = nil

begin
  kanji_db = DataKanji.create_from_file(kanji_data_file)
rescue StandardError => e
  warn("warning: could not fully load kanji data: #{e}")
end

def validate_keyword(db, keyword)
  return(true) if db.nil?
  return(true) unless db.respond_to?(:lookup_keyword)

  unless db.lookup_keyword(keyword)
    warn("warning: no kanji for keyword: #{keyword}")
  end

  return(true)
end


#
# Pre-scan to determine maximum number of keywords per line
#
max_pairs = 0

File.foreach(confusible_path) do |line|
  parts = parse_line(line)
  next if parts.nil?

  max_pairs = parts.length() if parts.length() > max_pairs
end


#
# Output page
#

puts("<!DOCTYPE html>")
puts("<html>")
puts("<head>")
puts("<title>Confusible Kanji</title>")
puts("<link rel=\"stylesheet\" type=\"text/css\" href=\"japanese.css\"/>")
puts("<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">")

puts("<style>")
puts("table.example th {")
puts("  min-width: 4em;")
puts("}")
puts("")
puts("table.example th.wide {")
puts("  min-width: 12em;")
puts("}")
puts("")
puts("td.kanji {")
puts("  font-size: 200%;")
puts("  text-align: center;")
puts("  border: 1px solid #ccc;")
puts("  cursor: pointer;")
puts("  min-width: 2em;")
puts("}")
puts("")
puts("td.kanji span {")
puts("  visibility: hidden;")
puts("}")
puts("")
puts("td.kanji:hover span {")
puts("  visibility: visible;")
puts("}")
puts("</style>")
puts("</head>")
puts("")
puts("<body>")
puts("")

puts("<h1>Confusible Kanji</h1>")


puts()
puts("Each row in this table contains a set of kanji keywords that are easily confused. In each case hover over the cell to the right of the keyword to reveal the associated kanji.")
puts("<BR/>")
puts("<BR/>")
puts()

puts("<table class=\"example\">")

#
# Process input
#

File.foreach(confusible_path) do |line|
  parts = parse_line(line)
  next if parts.nil?

  puts("")
  puts("<tr>")

  parts.each do |kw|
    validate_keyword(kanji_db, kw)

    puts("<td>#{kw}</td>")
    puts("<td class=\"kanji\"><span>#{keyword_to_kj(kw)}</span></td>")
  end

  #
  # Pad remaining columns so every row has equal width
  #
  missing_pairs = max_pairs - parts.length()

  if missing_pairs > 0
    puts("<td colspan=\"#{missing_pairs * 2}\"></td>")
  end


  puts("</tr>")
end

puts("")
puts("</table>")
puts("")
puts("<BR/><BR/>")
puts('Back to the <a href="study-material.html"> study progress page</a> or the <a href="index.html">main index</a>.')

puts("</body>")
puts("</html>")

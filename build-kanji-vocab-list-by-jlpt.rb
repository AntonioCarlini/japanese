#!/usr/bin/ruby -w
#encoding: UTF-8

$LOAD_PATH << File.dirname(__FILE__)

require 'DataKanji.rb'
require 'DataKanjidic.rb'
require 'Japanese.rb'

def html_strip(text)
  text.gsub!(%r{</?span [^>]*>}ixm, "")
  text.gsub!(/\r\n/, "")
  return text
end

class TableData

  attr_reader :kanji
  attr_reader :kana
  attr_reader :english

  def initialize(kanji, kana, english)
    @kanji = kanji
    @kana = kana
    @english = english
  end
end

def display_revision_table(title, entries)
  entries_per_line = 5

  puts('<table class="progress">')
  puts(' <tr> <th colspan="' + entries_per_line.to_s() + '">' + title + '</th>')
  puts(' <tr> <td colspan="' + entries_per_line.to_s() + '"></td>')

  count = 0
  entries.each() {
    |entry|
    count += 1
    data = entry[1]

    puts(" <tr>") if count == 1
    puts('   <td><div style="width: 12em" >')
    puts("   <span title=\"#{data.kana()} - #{data.english()}\">#{data.kanji()}</span></div></td>")
    if count == entries_per_line
      puts(" </tr>")
      count = 0
    end

  }

  while count < entries_per_line
    count += 1
    puts("<tc> </td> ")
    puts(" </tr>") if count == entries_per_line
  end

  puts("</table>")
  puts("</br></br>")
end

def display_alt_table(title, entries)
  puts('<table class="progress">')
  puts(' <tr> <th colspan="4">' + title + '</th>')
  puts(" <tr>")
  puts("   <th> Kanji  </th>")
  puts("   <th> Annotation  </th>")
  puts("   <th> Kana  </th>")
  puts("   <th> Meaning  </th>")
  puts(" </tr>")

#  count = 0
  entries.each() {
    |entry|
    output = entry[0]
    data = entry[1]

    puts(" <tr>")
    puts("   #{data.kanji()}</td>")
    puts("   <td colspan=3> &nbsp; </td>")
    puts("   <td> #{output}</td>")
    puts("   <td> #{data.kana()}</td>")
    puts("   <td> #{data.english()}</td>")
    puts(" </tr>")
  }

  puts("</table>")
end

# ARGV[0] - JLPT level (N1..N5,1..4)
# ARGV[1] - vocabulary web page
# ARGV[2] - kanji.data


level = ARGV.shift()
vocab_file = ARGV.shift()
kanji_data_file = ARGV.shift()

# The JLPT level can be indicated as N1..N5 or 1..4.
# However the KANJIDIC data only knows about the old JLPT levels.
# So convert using N1 => 1, N2 => 2, N3 => 2, N4 => 3 etc.
converter = { :N1 => 1, :N2 => 2, :N3 => 2, :N4 => 3, :N5 => 4, :"1" => 1, :"2" => 2, :"3" => 3, :"4" => 4 }

jlpt = converter[level.upcase().to_sym()]

raise("Bad JLPT level: [#{level}]") if jlpt.nil?()

# An example entry is shown below.
# It begins with <tr style='mso-yfti-irow:\d'> and ends with </tr>
# Within that look for three lots of <td> ... </td>
# These are kanji, kana and English.
# Within those of those look for <span ...>(.*)</span>.
# The first entry (kanji) may be blank but the others cannot be.

=begin
 <tr style='mso-yfti-irow:4'>
  <td style='background:white;padding:7.5pt 7.5pt 7.5pt 7.5pt'>
  <p class=MsoNormal style='margin-bottom:0cm;margin-bottom:.0001pt;line-height:
  normal'><span lang=EN-US style='font-size:11.5pt;font-family:"MS Mincho";
  mso-bidi-font-family:"MS Mincho";color:black'>&#38291;</span><span
  lang=EN-US style='font-size:11.5pt;font-family:Arial;mso-fareast-font-family:
  "Times New Roman";color:black'><o:p></o:p></span></p>
  </td>

  <td style='background:white;padding:7.5pt 7.5pt 7.5pt 7.5pt'>
  <p class=MsoNormal style='margin-bottom:0cm;margin-bottom:.0001pt;line-height:
  normal'><span lang=EN-US style='font-size:11.5pt;font-family:"MS Mincho";
  mso-bidi-font-family:"MS Mincho";color:black'>&#12354;&#12356;&#12384;</span><span
  lang=EN-US style='font-size:11.5pt;font-family:Arial;mso-fareast-font-family:
  "Times New Roman";color:black'><o:p></o:p></span></p>
  </td>

  <td style='background:white;padding:7.5pt 7.5pt 7.5pt 7.5pt'>
  <p class=MsoNormal style='margin-bottom:0cm;margin-bottom:.0001pt;line-height:
  normal'><span lang=EN-US style='font-size:11.5pt;font-family:Arial;
  mso-fareast-font-family:"Times New Roman";color:black'>a space<o:p></o:p></span></p>
  </td>
 </tr>
=end

text = IO.read(vocab_file).force_encoding("ISO-8859-1")

expected_row = 1

vocab_data = []

text.scan(%r{<tr \s+ style=(?:3D)?\'mso-yfti-irow:(\d+)\'>(.*?)</tr>}ixm) {
  |row, tr_contents|

  next if row =~ /^0$/  # Row 0 is the table heading

  raise("expected row #{expected_row} but found #{row}") if row.to_i() != expected_row

  tr_contents.scan(%r{<td[^>]*?>(.*?)</td> .*? <td[^>]*?>(.*?)</td> .*? <td[^>]*?>(.*?)</td>}ixm) {
    |td_A, td_B, td_C|
    kanji = nil
    kana = nil
    english = nil
    td_A.scan(%r{<span [^>]*> (.*?)</span> (.*?) <span [^>]*> .*?</span>}ixm) { |jp, en| kanji = jp }
    td_B.scan(%r{<span [^>]*> (.*?)</span> (.*?) <span [^>]*> .*?</span>}ixm) { |jp, en| kana = jp }
    td_C.scan(%r{<span [^>]*> (.*?)<o:p></o:p></span>}ixm) { |en| english = html_strip(en.first()) }
    vocab_data << TableData.new(kanji, kana, english) unless kanji.nil?()
  }

  expected_row += 1
}

# Read the Heisig kanji from the kanji data file.
kanji_data = DataKanji.create_from_file(kanji_data_file)

# Now build a hash of unicode => kanji
unicode_2_kanji = {}

kanji_data.kanji().each() {
  |k|
  unicode_2_kanji[k.unicode()] = k
}

# Go through each entry.
# Anything not in the kanji list is presumed to be kana.
# Build three lists:
# All-known words (i.e. a mixture of kana and/or only known kanji)
# Words with some unknown and some known kanji (and possibly some kana).
# Words with all unknown kanji (and possibly some kana).

all_known_list = []
some_known_list = []
all_unknown_list = []

vocab_data.each() {
  |data|
  unicode_chars = data.kanji.scan(/&#(\d+);/) # Could be kanji or kana ...

  all_kana = true
  some_known_kanji = false
  some_unknown_kanji = false
  output = ""
  unicode_chars.each() {
    |ch|
    char_code = ch.first().to_i()
    output += "&#x%4.4x" % char_code
    k = unicode_2_kanji[char_code]
    next if k.nil?()   # This is presumed to be kana
    all_kana = false
    if k.jlpt() >= jlpt
      # This is a known kanji at this level
      output += "[K:#{k.jlpt()}]"
      some_known_kanji = true
    else
      # This is an unknown kanji at this level
      output += "[U:#{k.jlpt()}]"
      some_unknown_kanji = true
    end      
  }

  entry = [output, data]
  # If there are no unknown kanji, this word is completely knowable
  if !some_unknown_kanji
    all_known_list << entry
  elsif some_known_kanji
    some_known_list << entry
  else
    all_unknown_list << entry
  end
}

# Now spit out three tables to the output stream

=begin
puts('<table class="progress">')
puts(' <tr> <th colspan="4"> Vocabulary that Should be Fully Known </th>')
puts(" <tr>")
puts("   <th> Kanji  </th>")
puts("   <th> Annotation  </th>")
puts("   <th> Kana  </th>")
puts("   <th> Meaning  </th>")
puts(" </tr>")
=end

display_revision_table("Vocabulary that Should be Fully Known", all_known_list)

=begin
all_known_list.each() {
  |entry|
  output = entry[0]
  data = entry[1]

  puts(" <tr>")
  puts("   <td> <span title=\"#{data.kana()} - #{data.english()}\">#{data.kanji()}</span></td>")
  puts("   <td colspan=3> &nbsp; </td>")
#  puts("   <td> #{output}</td>")
#  puts("   <td> #{data.kana()}</td>")
#  puts("   <td> #{data.english()}</td>")
  puts(" </tr>")
}

puts("</table>")
=end

=begin
puts('<table class="progress">')
puts(' <tr> <th colspan="4"> Vocabulary that Should be Partially Known </th>')
puts(" <tr>")
puts("   <th> Kanji  </th>")
puts("   <th> Annotation  </th>")
puts("   <th> Kana  </th>")
puts("   <th> Meaning  </th>")
puts(" </tr>")

some_known_list.each() {
  |entry|
  output = entry[0]
  data = entry[1]

  puts(" <tr>")
  puts("   <td> #{data.kanji()}</td>")
  puts("   <td> #{output}</td>")
  puts("   <td> #{data.kana()}</td>")
  puts("   <td> #{data.english()}</td>")
  puts(" </tr>")
}

puts("</table>")
=end

display_revision_table("Vocabulary that Should be Partially Known", some_known_list)

=begin
puts('<table class="progress">')
puts(' <tr> <th colspan="4"> Vocabulary that is NOT required </th>')
puts(" <tr>")
puts("   <th> Kanji  </th>")
puts("   <th> Annotation  </th>")
puts("   <th> Kana  </th>")
puts("   <th> Meaning  </th>")
puts(" </tr>")

all_unknown_list.each() {
  |entry|

  output = entry[0]
  data = entry[1]

  puts(" <tr>")
  puts("   <td> #{data.kanji()}</td>")
  puts("   <td> #{output}</td>")
  puts("   <td> #{data.kana()}</td>")
  puts("   <td> #{data.english()}</td>")
  puts(" </tr>")
}

puts("</table>")
=end

display_revision_table("Vocabulary that is NOT required", all_unknown_list)

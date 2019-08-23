#!/usr/bin/ruby -w
# coding: utf-8

$LOAD_PATH << File.dirname(__FILE__)

require 'DataKanji.rb'
require 'FastKanji.rb'
require 'Kanji.rb'

#+
# This script takes a table of contents for "A Handbook of Japanese Grammar Patterns for Teachers and Learners"
# and converts it to JHTML (i.e. HTML with embedded @-codes for the Japanese text).
#
# This is a one-off conversion that will almost certainly not need to be repeated but the script is being recorded
# in case it proves to be a useful template for future conversions of web pages into @-codes.
#-

# Start of HiraganaSupport code

$UNICODE_2_HI_JHTML = {
  65288 => "(",
  65289 => ")",
  12308 => "(",
  12309 => ")",
  12289 => ',',
  12290 => '.',
  12300 => '[',
  12301 => ']',
  12353 => 'xa', 12355 => 'xi', 12357 => 'xu', 12359 => 'xe', 12361 => 'xo', 
  12354 => 'a',  12356 => 'i',  12358 => 'u',  12360 => 'e',  12362 => 'o', 
  12363 => 'ka', 12364 => 'ga', 12365 => 'ki', 12366 => 'gi', 12367 => 'ku', 12368 => 'gu', 12369 => 'ke', 12370 => 'ge', 12371 => 'ko', 12372 => 'go', 
  12373 => 'sa', 12374 => 'za', 12375 => 'shi', 12376 => 'ji', 12377 => 'su', 12378 => 'zu', 12379 => 'se', 12380 => 'ze', 12381 => 'so', 12382 => 'zo', 
  12383 => 'ta', 12384 => 'da', 12385 => 'chi', 12386 => 'di', 12388 => 'tsu', 12389 => 'du', 12390 => 'te', 12391 => 'de', 12392 => 'to', 12393 => 'do', 
  12387 => 'xtsu',
  12394 => 'na', 12395 => 'ni', 12396 => 'nu', 12397 => 'ne', 12398 => 'no',
  12399 => 'ha', 12400 => 'ba', 12401 => 'pa', 12402 => 'hi', 12403 => 'bi', 12404 => 'pi', 12405 => 'fu', 12406 => 'bu', 12407 => 'pu', 12408 => 'he', 12409 => 'be', 12410 => 'pe', 12411 => 'ho', 12412 => 'bo', 12413 => 'po',
  12414 => 'ma', 12415 => 'mi', 12416 => 'mu', 12417 => 'me', 12418 => 'mo',
  12419 => 'xya', 12421 => 'xyu', 12423 => 'xyo',
  12420 => 'ya', 12422 => 'yu', 12424 => 'yo',
  12425 => 'ra', 12426 => 'ri', 12427 => 'ru', 12428 => 're', 12429 => 'ro',
  12430 => 'xwa',
  12431 => 'wa', 12432 => 'wi', 12433 => 'we', 12434 => 'wo',
  12435 => "n'",
  12436 => 'vu'
}

def convert_unicode_to_hiragana_jhtml(code)
  ans = $UNICODE_2_HI_JHTML[code]
  return ans
end

# End of HiraganaSupport code

def convert_unicode_to_katakana_jhtml(code)
  return '-' if code == 12540 # katakana -
  ans = $UNICODE_2_HI_JHTML[code - 96]
  return ans
end

def classify_codepoint(codepoint)
  if codepoint <= 127
    if codepoint.chr() == '<'
      return :furigana_start
    elsif codepoint.chr() == '>'
      return :furigana_end
    else
      return :ascii
    end
  elsif (codepoint == 0x3001) ||(codepoint == 0x3002)
    return :punctuation
  elsif (codepoint >= 0x3040) && (codepoint <= 0x309F)
    return :hiragana
  elsif (codepoint == 65288) || (codepoint == 65289)
    return :hiragana
  elsif (codepoint >= 0x30A0) && (codepoint <= 0x30FF)
    return :katakana
  else
    return :kanji
  end
end

def convert_to_at_codes(line, kjuc)
  output = ""
  
  ji = line.chomp().unpack('U*')

  # Work backwards through the string, ignoring spaces
  current_mode = :hiragana

  #output += "@HI{{"
  
  pending = ""
  pending_kanji = ""

  ji.each() {
    |codepoint|
    style = classify_codepoint(codepoint)
    style = :hiragana if style == :punctuation # TODO: punctuation in katakana??

    # If the style has changed (e.g. katakana has ended and kanji has started ...) output the accumulated stuff

    # After kanji ... do special?
    if current_mode == :kanji && style != :kanji
      if style == :furigana_start
        current_mode = :furigana
        next # do not process the '<' that shoved us into furigana mode
      elsif style == :furigana_end
        # only allowed in :furigana mode
        raise
      else
        # Kanji followed by no furigana indicator ... output the kanji
        output += "@KJ{{#{pending_kanji}}}"
        pending_kanji = ""
      end
    elsif style != current_mode
      case current_mode
      when :katakana
        output += "@KT{{#{pending}}}" unless pending.empty?()
      when :hiragana
        output += pending unless pending.empty?()
      when :furigana
        raise unless style == :hiragana || style == :furigana_end # will accumulate below but must be hiragana or end of furigana
        if style == :furigana_end
          output += "@FG{{@KJ{{#{pending_kanji}}}:#{pending}}}"
          pending_kanji = ""
          pending = ""
          current_mode = :hiragana ## ???
          next # do not process the furigana_end '>' that triggered this
        end
      when :ascii
        output += pending unless pending.empty?()
      when :kanji
        raise
      when :furigana_end
        puts("END FG")
        output += "@FG{{@KJ{{#{pending_kanji}}}:#{pending}}}"
        pending_kanji = ""
        pending = ""
      else
        raise("Failed to account for #{current_mode}")
      end
      pending = ""
    end

    case style
    when :furigana
      pending += codepoint.chr()
    when :hiragana
      current_mode = :hiragana unless current_mode == :furigana
      pending += convert_unicode_to_hiragana_jhtml(codepoint)
    when :katakana
      current_mode = :katakana
      pending += convert_unicode_to_katakana_jhtml(codepoint)
    when :kanji
      pending_kanji += "^" if current_mode == :kanji
      current_mode = :kanji
      begin
        pending_kanji += "#{kjuc[codepoint].english()[0].gsub(/\s+/,'*')}"
      rescue
        puts("Failed codepoint is #{codepoint}  line is [#{line}]")
      end
    when :ascii
      current_mode = :ascii
      pending += codepoint.chr()
    end
  }

  case current_mode
  when :katakana
    output += "@KT{{#{pending}}}"
  when :hiragana
    output+= "@HI{{#{pending}}}"
  when :ascii
    output += pending
  when :kanji
    # TODO wait ... see if next if furigana is coming
    output += "@KJ{{#{pending_kanji}}}"
    pending_kanji = ""
  else
    raise("Failed to account for #{style}")
  end
  #output += "}}" unless current_mode == :ascii

  return output
end

# Code starts here

puts('<!DOCTYPE html>')
puts('<html>')
puts('<head>')
puts('<title>A Handbook of Japanese Grammar Patterns for Teachers and Learners</title>')
puts('<link rel="stylesheet" type="text/css" href="japanese.css" />')
puts('<meta http-equiv="Content-Type" content="text/html; charset=utf-8">')
puts('</head>')
puts('<style>')
puts('table.progress td.left {')
puts(' text-align: left')
puts('}')
puts('</style>')
puts('<body>')
puts('<h1>A Handbook of Japanese Grammar Patterns for Teachers and Learners</h1>')
puts()
puts('<table class="progress">')
puts('<tr>')
puts('  <th colspan="2"> &nbsp; </th> <th colspan="2"> SRS </th> <th> Studied </th> <th> Grammar </th>')
puts('</tr>')
puts('<tr>')
puts('  <th> Heading </th>')
puts('  <th> Location </th>')
puts('  <th> Vocabulary </th> <th> Sentences </th> <th> Grammar </th> <th> Notes Made </th>')
puts('</tr>')

expected_row = 1

kanji_data_file = "data/kanji.data" # Hard code this for now
kanji_data = DataKanji.create_from_file(kanji_data_file)
kanji = kanji_data.kanji()

kjuc = []  # list of kanji indexed by unicode

kanji.each() {
  |obj|
  uc = obj.unicode()
  raise("Saw ##{uc} more than once.") unless kjuc[uc].nil?()
  kjuc[uc] = obj
}

kanji_noma = Kanji.new(99999, 0x3005, 'none', 'none', 'none', ['noma'], 9, 1)
kjuc[0x3005] = kanji_noma
td_width = 109

ARGF.each() {
  |line|
  line.chomp!()

  # If we see 3 dots, fix that up
  line.gsub!(/…/, "@JDOTS3{{}}")
  
  # Only care about lines of the form
  #    <tr id="row#"> ... </tr>
  # where # is a number specified as decimal digits
  next unless line =~ /\s*<tr id="row(\d+)"\s+class="rows">/
  row = $1.to_i()

  # Check that the row number is as expected
  raise("Expected row #{expected_row} but found #{row} in [#{line}]") if row != expected_row

  if line =~ /<a href[^>]+>(.+)<sub>(\d+)<\/sub><\/a>.*<td class="minimal">(\d+) \(\d+\)<\/td><\/tr>/
    # This matches a keyword with a subscript
    keyword = $1
    superscript = $2
    page = $3.to_i()
  elsif line =~ /<a href[^>]+>(.+)<\/a>.*<td class="minimal">(\d+) \(\d+\)<\/td><\/tr>/
    # This matches a keyword without a superscript
    keyword = $1
    superscript = nil
    page = $2.to_i()
  elsif
    raise("No match on [#{line}]")
  end

  furigana = nil
  
  # Look for the furigana in a section like this:
  #   <rt class="form" data-id="95" data-concept="かぎる">かぎる</rt>
  if line =~ /<rt [^>]+>(.*)<\/rt>/
    furigana = $1
  end
  
  final_hiragana = nil
  at_keyword = convert_to_at_codes(keyword, kjuc)
  at_furigana = nil
  at_furigana = convert_to_at_codes(furigana, kjuc) unless furigana.nil?()

  if !at_furigana.nil?() && at_keyword =~ /(.*)@HI{{(.*?)}}$/
    remaining_fg = $1
    trailing_hiragana = $2
    ## puts("PRE-MOD: [#{at_keyword}/#{at_furigana}] => rem:[#{remaining_fg}]/trail:[#{trailing_hiragana}]")
    # If the ending hiragana matches the end portion of the furigana ...
    if at_furigana.end_with?(trailing_hiragana + '}}')
      ## print("MOD: [#{at_keyword}/#{at_furigana}] =>")
      # move that outwards
      final_hiragana = trailing_hiragana
      at_furigana = at_furigana.sub(/#{final_hiragana}}}$/, '}}')
      at_keyword = remaining_fg
      ## puts( "[#{at_keyword}/#{at_furigana}] + #{final_hiragana} =>")
    end
  end


  # Look for the next row
  expected_row += 1

  text = at_keyword
  unless furigana.nil?()
    text = "@FG{{#{at_keyword}:#{at_furigana}}}"
  end
  unless final_hiragana.nil?()
    text += '@HI{{' + final_hiragana + '}}'
  end
  unless superscript.nil?()
    text += "<sup>#{superscript}</sup>"
  end

  puts('<tr>')
  print('  <td class="left"> <a href=""></a>')
  print("#{text}")
  print(' ' * (td_width - text.length()))
  puts("</td>")
  print('  <td class="left"> p. ')
  print("%-3d" % page)
  puts(' ' * (td_width - 9 + 18) + "</td>")
  puts('  <td class=""> </td> <td class=""> </td> <td class=""> </td> <td class=""> </td>')
  puts('</tr>')
}

puts('</table>')
puts()
puts('</body>')
puts('</html>')

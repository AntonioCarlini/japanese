#!/usr/bin/ruby -w
#encoding: UTF-8

$LOAD_PATH << File.dirname(__FILE__)

require 'DataKanji.rb'
require 'FastKanji.rb'
require 'Kanji.rb'
  
# Start of HiraganaSupport code

$UNICODE_2_HI_JHTML = {
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
  elsif (codepoint >= 0x30A0) && (codepoint <= 0x30FF)
    return :katakana
  else
    return :kanji
  end
end

# Accept input and recompose to a form using @HI{{...}} etc.
#
# Currently does not output dummy @FG{{}} around kanji.
#
# Input example:
# 音楽はクラシクに限らず何でも聴きます。
#

puts("------vvvvv------")
line = ARGV.join()
puts line
puts("------^^^^^------")

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

ji = line.chomp().unpack('U*')

# Work backwards through the string, ignoring spaces
current_mode = :hiragana
count = 0
print("@HI{{")
pending = ""
pending_kanji = ""

ji.each() {
  |codepoint|
  style = classify_codepoint(codepoint)
  style = :hiragana if style == :punctuation # TODO: punctuation in katakana??

  ##puts("code: #{codepoint}  style=#{style} current_mode=#{current_mode}")

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
      print("@KJ{{#{pending_kanji}}}")
      pending_kanji = ""
    end
  elsif style != current_mode
    case current_mode
    when :katakana
      print("@KT{{#{pending}}}") unless pending.empty?()
    when :hiragana
      print(pending) unless pending.empty?()
    when :furigana
      raise unless style == :hiragana || style == :furigana_end # will accumulate below but must be hiragana or end of furigana
      if style == :furigana_end
        print("@FG{{@KJ{{#{pending_kanji}}}:#{pending}}}")
        pending_kanji = ""
        pending = ""
        current_mode = :hiragana ## ???
        next # do not process the furigana_end '>' that triggered this
      end
    when :ascii
      print(pending) unless pending.empty?()
    when :kanji
      raise
    when :furigana_end
      puts("END FG")
      print("@FG{{@KJ{{#{pending_kanji}}}:#{pending}}}")
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
    pending_kanji += "#{kjuc[codepoint].english()[0].gsub(/\s+/,'*')}"
  when :ascii
    current_mode = :ascii
    pending += codepoint.chr()
  end
}

case current_mode
when :katakana
  print("@KT{{#{pending}}}")
when :hiragana
  print("@HI{{#{pending}}}")
when :ascii
  print(pending)
when :kanji
  # TODO wait ... see if next if furigana is coming
  print("@KJ{{#{pending_kanji}}}")
  pending_kanji = ""
else
  raise("Failed to account for #{style}")
end
print("}}") unless current_mode == :ascii
puts()

#!/usr/bin/ruby -w
#encoding: UTF-8

$LOAD_PATH << File.dirname(__FILE__)

#+
# Provide support for reading data from a kanjidic file.
# The format is described here: http://www.csse.monash.edu.au/~jwb/kanjidic.html.
# Not all fields are currently supported.
#-

# Each kanji is represented by one Kanji object
class Kanji

  attr_reader :english
  attr_reader :heisig
  attr_reader :idents
  attr_reader :jlpt
  attr_reader :jouyou
  attr_reader :kunyomi
  attr_reader :nanori
  attr_reader :onyomi
  attr_reader :unicode

  def initialize(heisig, unicode, onyomi, kunyomi, nanori, english, jouyou, jlpt)
    @heisig = heisig
    @unicode = unicode
    @onyomi = onyomi
    @kunyomi = kunyomi
    @nanori = nanori
    @english = english
    @jouyou = jouyou
    @jlpt = jlpt
    @idents = []
  end

  def grade()
    @jouyou
  end

  def add_reading(reading)
    # Stop if the reading does not show up in onyomi or kunyomi
    raise("Claimed reading [#{reading}] for [#{@unicode}] is wrong") unless @onyomi.include?(reading) || @kunyomi.include?(reading)
    @idents << reading
  end
end

# Given a unicode japanese kana stream, turn it back into SOMETHING

$hiragana = {
  0x2422 => :A,
  0x2424 => :I,
  0x2426 => :U,
  0x2428 => :E,
  0x242A => :O,
  0x242B => :KA,
  0x242C => :GA,
  0x242D => :KI,
  0x242E => :GI,
  0x242F => :KU,
  0x2430 => :GU,
  0x2431 => :KE,
  0x2432 => :GE,
  0x2433 => :KO,
  0x2434 => :GO,
  0x2435 => :SA,
  0x2436 => :ZA,
  0x2437 => :SHI,
  0x2438 => :JI,   # listed as ZI in the original table
  0x2439 => :SU,
  0x243A => :ZU,
  0x243B => :SE,
  0x243C => :ZE,
  0x243D => :SO,
  0x243E => :ZO,
  0x243F => :TA,
  0x2440 => :DA,
  0x2441 => :CHI,
  0x2442 => :DI,
  0x2443 => :chisai_TSU,
  0x2444 => :TSU,
  0x2445 => :DU,
  0x2446 => :TE,
  0x2447 => :DE,
  0x2448 => :TO,
  0x2449 => :DO,
  0x244A => :NA,
  0x244B => :NI,
  0x244C => :NU,
  0x244D => :NE,
  0x244E => :NO,
  0x244F => :HA,
  0x2450 => :BA,
  0x2451 => :PA,
  0x2452 => :HI,
  0x2453 => :BI,
  0x2454 => :PI,
  0x2455 => :FU,
  0x2456 => :BU,
  0x2457 => :PU,
  0x2458 => :HE,
  0x2459 => :BE,
  0x245A => :PE,
  0x245B => :HO,
  0x245C => :BO,
  0x245D => :PO,
  0x245E => :MA,
  0x245F => :MI,
  0x2460 => :MU,
  0x2461 => :ME,
  0x2462 => :MO,
  0x2463 => :chisai_YA,
  0x2464 => :YA,
  0x2465 => :chisai_YU,
  0x2466 => :YU,
  0x2467 => :chisai_YO,
  0x2468 => :YO,
  0x2469 => :RA,
  0x246A => :RI,
  0x246B => :RU,
  0x246C => :RE,
  0x246D => :RO,
  0x246F => :WA,
  0x2470 => :WI,
  0x2471 => :WE,
  0x2472 => :WO,
  0x2473 => :N,
}

$katakana = {
  0x213C => :"-",
  0x2522 => :A,
  0x2523 => :CHISAI_I,
  0x2524 => :I,
  0x2525 => :CHISAI_U,
  0x2526 => :U,
  0x2527 => :CHISAI_E,
  0x2528 => :E,
  0x2529 => :CHISAI_O,
  0x252A => :O,
  0x252B => :KA,
  0x252C => :GA,
  0x252D => :KI,
  0x252E => :GI,
  0x252F => :KU,
  0x2530 => :GU,
  0x2531 => :KE,
  0x2532 => :GE,
  0x2533 => :KO,
  0x2534 => :GO,
  0x2535 => :SA,
  0x2536 => :ZA,
  0x2537 => :SHI,
  0x2538 => :JI,   # listed as ZI in the original table
  0x2539 => :SU,
  0x253A => :ZU,
  0x253B => :SE,
  0x253C => :ZE,
  0x253D => :SO,
  0x253E => :ZO,
  0x253F => :TA,
  0x2540 => :DA,
  0x2541 => :CHI,
  0x2542 => :DI,
  0x2543 => :CHISAI_TSU,
  0x2544 => :TSU,
  0x2545 => :DU,
  0x2546 => :TE,
  0x2547 => :DE,
  0x2548 => :TO,
  0x2549 => :DO,
  0x254A => :NA,
  0x254B => :NI,
  0x254C => :NU,
  0x254D => :NE,
  0x254E => :NO,
  0x254F => :HA,
  0x2550 => :BA,
  0x2551 => :PA,
  0x2552 => :HI,
  0x2553 => :BI,
  0x2554 => :PI,
  0x2555 => :HU,
  0x2556 => :BU,
  0x2557 => :PU,
  0x2558 => :HE,
  0x2559 => :BE,
  0x255A => :PE,
  0x255B => :HO,
  0x255C => :BO,
  0x255D => :PO,
  0x255E => :MA,
  0x255F => :MI,
  0x2560 => :MU,
  0x2561 => :ME,
  0x2562 => :MO,
  0x2563 => :CHISAI_YA,
  0x2564 => :YA,
  0x2565 => :CHISAI_YU,
  0x2566 => :YU,
  0x2567 => :CHISAI_YO,
  0x2568 => :YO,
  0x2569 => :RA,
  0x256A => :RI,
  0x256B => :RU,
  0x256C => :RE,
  0x256D => :RO,
  0x256E => :CHISAI_WA,
  0x256F => :WA,
  0x2570 => :WI,
  0x2571 => :WE,
  0x2572 => :WO,
  0x2573 => :N,
  0x2574 => :VU,
  0x2575 => :CHISAI_KA,
  0x2576 => :CHISAI_KE,
}

# Turns EUC-JP encoded kana back into ASCII romanaisation of the name
# EUC-JP encoding is roughly: 
# 0x21 .. 0x7E: single bytes, ASCII
# 0xA1 .. 0xFE: two bytes, represent JIS X 0208 character
# 0x81: three bytes (the remaining two being 0xA1 .. 0xFE), represents a JIS X 0212 character.
#
# To arrive at the JIS X 0208 character, subtract 0x80 from each byte.
def process_japanese(line, entry)
  result = []
  style = nil
  # unpack as unsigned byte array ("C*")
  values = entry.unpack("C*")
  until values.empty?()
    data = values.shift()
    if data < 0x7F
      result << data.chr()
    else
      # Must be first of a pair, each in the range 0xA1-0xFE
      data = 256*(data - 0x80) + (values.shift() - 0x80)
      # data should now be a 16 bit value representing a kana
      # If it is not in either of the kana lists, something is wrong
      h = $hiragana[data]
      k = $katakana[data]
      if h.nil?() && k.nil?()
        puts("Line #{line}: data [#{data}/#{"%4.4x" % data}] (#{data})is not kana")
        return :neither,""
      elsif h.nil?() == k.nil?()
        puts("Line #{line}: data [#{data}] is BOTH kana") 
        return :both,""
      end

      unless h.nil?()
        raise("Line: \{line}: [#{result.join()}] was KATAKANA but now HIRAGANA?") if style == :katakana
        style = :hiragana
        result << h.to_s()
        #puts("ADDED (#{data}} hiaragana #{h.to_s()}")
      end
      unless k.nil?()
        raise("Line: #{line}: [#{result.join()}] was HIRAGANA but now KATAKANA?") if style == :hiragana
        style = :katakana
        result << k.to_s()
        # puts("ADDED (#{data}} katakana #{k.to_s()}")
      end
    end
  end

  answer = result.join()

  # Try to fix nyo == n'yo
  answer.gsub!(/ny/, "n'y")

  # Fix doubled consonants
  answer.gsub!(/chisai_tsuk(a|i|u|e|o)/ix, 'kk\1')
  answer.gsub!(/chisai_tsup(a|i|u|e|o)/ix, 'pp\1')
  answer.gsub!(/chisai_tsut(a|su|e|o)/ix, 't\1')
  answer.gsub!(/chisai_tsuchi/ix, 'cchi')
  answer.gsub!(/chisai_tsus(a|u|e|o)/ix, 'ss\1')
  answer.gsub!(/chisai_tsushi/ix, 'sshi')

  # Fix small ya yu yo
  # ri mi pi bi hi ni gi ki => rya etc.
  # ji => ja, chi => cha shi => sha zi=> zya

  answer.gsub!(/(r|m|p|b|h|n|g|k)ichisai_ya/ix, '\1ya')
  answer.gsub!(/(r|m|p|b|h|n|g|k)ichisai_yu/ix, '\1yu')
  answer.gsub!(/(r|m|p|b|h|n|g|k)ichisai_yo/ix, '\1yo')
  answer.gsub!(/(j|ch|sh)ichisai_ya/ix, '\1a')
  answer.gsub!(/(j|ch|sh)ichisai_yu/ix, '\1u')
  answer.gsub!(/(j|ch|sh)ichisai_yo/ix, '\1o')

  answer.upcase!()   if style == :katakana
  answer.downcase!() if style == :hiragana

  return style,answer
end

class DataKanjidic

  # The kanjidic format consists of a number of space separated components.
  # First comes the kanji itself (EUC-JP encoded) and then the JIS code.
  # The remaining items are prefixed by one (or more) identifying letters.
  # This is then followed by a number of EUC-JP encoded readings, possibly a T1 and further readings
  # which are used only for names.
  # Finally the daat line ends with one or more English meanings, each enclosed in curly brackets.
  #
  # The following components are supported:
  #
  # U the unicode value for the kanji symbol
  # G the "grade" of the kanji, In this case, G2 means it is a Jouyou kanji taught in school grade 2.
  # L the index in Heisig (Remembering The Kanji);
  #
  # Kanji without a Heisig index number are currently ignored. An alternative index would be the
  # four-corner code (Q)
  #
  def DataKanjidic.create_from_file(filename, options = {})
    
    kanji_limit = 0      # By default do not limit number of kanji to read from file
    options.each() {
      |key, value|
      case key
      when :kanji_limit then    kanji_limit = value
      end
    }

    line_num = 0
    kanji_read = 0
    all_kanji = {}
    IO.read(filename).force_encoding("ISO-8859-1").each_line() {
      |line|
      line.chomp!()
      line_num += 1

      # Bail out if kanji limit reached (useful for testing).
      next if kanji_limit > 0 && kanji_read >= kanji_limit

      # Skip commented out lines
      next if line =~ /^ \s+ #/

      # English meanings come at the end of the list enclosed in curly parentheses.
      # A meaning might be two words such as {rice field}.
      # To simplify the scanning code, pull these out now
      full_line = line
      meaning = ""
      if line =~ /^(.*?) \s+ {(.*)} \s+$/ix
        line = $1
        meaning = "{#{$2}}"
      end
      fields = line.split()
      fields.shift() # kanji = fields.shift()
      fields.shift() # jis = fields.shift()
      unicode = -1
      grade = nil
      heisig = nil
      nanori = []
      onyomi = []
      kunyomi = []
      processing_nanori = false
      fields.each() {
        |entry|
        case entry[0]
        when 'U'  then unicode = entry[1..-1].to_i(16)
        when 'G'  then grade = entry[1..-1].to_i()
        when 'L'  then heisig = entry[1..-1].to_i()
        when /N|B|C|S|H|F|P|K|I|Q|M|E|Y/ then ;
        when /D|J|X|V|W|O|Z/ then;  # seemingly undocumented
        when /T/ then  processing_nanori = true
        when '{'  then raise("Bad line at #{line_num}: [#{full_line}]")
        else
          unless heisig.nil?()
            style,result = process_japanese(line_num, entry)
            if processing_nanori
              nanori << result
            else
              onyomi << result  if style == :katakana
              kunyomi << result if style == :hiragana
            end
          end
        end
      }

      kanji_read += 1

      # Ignore non-Heisig kanji for now
      next if heisig.nil?()

      all_kanji[heisig] = Kanji.new(heisig, unicode, onyomi, kunyomi, nanori, meaning, grade, nil)
    }

    return all_kanji
  end
end

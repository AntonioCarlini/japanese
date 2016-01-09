#!/usr/bin/ruby -w

$LOAD_PATH << File.dirname(__FILE__)

require 'DebugSupport.rb'
require 'UnicodeSupport.rb'

def convert_to_hiragana(text)
  one = {
    :a  => 0x3042, :i =>  0x3044, :u =>  0x3046, :e  => 0x3048, :o  => 0x304a,
    :","  => 0x3001, :"." =>  0x3002, "[".to_sym() =>  0x300c, :"]"  => 0x300d
  }
  two = {
    :ka => 0x304b, :ki => 0x304d, :ku => 0x304f, :ke => 0x3051, :ko => 0x3053,
    :ga => 0x304c, :gi => 0x304e, :gu => 0x3050, :ge => 0x3052, :go => 0x3054,
    :sa => 0x3055, :si => 0x3057, :su => 0x3059, :se => 0x305b, :so => 0x305d,
    :za => 0x3056, :ji => 0x3058, :zu => 0x305a, :ze => 0x305c, :zo => 0x305e,
    :ta => 0x305f, :ti => 0x3061, :tu => 0x3064, :te => 0x3066, :to => 0x3068,
    :da => 0x3060, :di => 0x3062, :du => 0x3065, :de => 0x3067, :do => 0x3069,
    :na => 0x306a, :ni => 0x306b, :nu => 0x306c, :ne => 0x306d, :no => 0x306e,
    :ha => 0x306f, :hi => 0x3072, :fu => 0x3075, :he => 0x3078, :ho => 0x307b,
    :ba => 0x3070, :bi => 0x3073, :bu => 0x3076, :be => 0x3079, :bo => 0x307c,
    :pa => 0x3071, :pi => 0x3074, :pu => 0x3077, :pe => 0x307a, :po => 0x307d,
    :ma => 0x307e, :mi => 0x307f, :mu => 0x3080, :me => 0x3081, :mo => 0x3082,
    :ya => 0x3084,                :yu => 0x3086,                :yo => 0x3088,
    :ra => 0x3089, :ri => 0x308a, :ru => 0x308b, :re => 0x308c, :ro => 0x308d,
    :wa => 0x308f, :wi => 0x3090,                :we => 0x3091, :wo => 0x3092,
    :nn => 0x3093, :"n'" => 0x3093,
    :xa => 0x3041, :xi => 0x3043, :xu => 0x3045, :xe => 0x3045, :xo => 0x3049,
    :vu => 0x3094,
    # Alternatives below here
    :ji => 0x3058,
    :hu => 0x3075,
  }
  three = { :shi => 0x3057, :chi => 0x3061, :tsu => 0x3064, :xya => 0x3083, :xyu => 0x3085, :xyo => 0x3087, :xwa => 0x308e }
  digraph2 = { :ya => 0x3083, :yu => 0x3085, :yo => 0x3087 }
  four = { :xtsu => 0x3063 }
  result = ""
  current = ""
  pos = 0
  text.chars() {
    |c|
    pos += 1
    current += c
    if current =~ /^[0-9]$/
      result << current
      current = ""
      next
    end

    ch = current.downcase().to_sym()
    case current.length()
    when 1
      s = one[ch]
      if !s.nil?()
        # Single char translation works
        result << jp_unicode(s)
        current = ""
      elsif current =~ /^\s*$/
        result << current
        current = ""
      elsif current =~ /[^[:alnum:]]/
        result << current
        current = ""
      end
    when 2
      s = two[current.downcase().to_sym()]
      if !s.nil?()
        # Two char translation works
        result << jp_unicode(s)
        current = ""
      elsif current[0,1] == current[1,1]
        result << jp_unicode(0x3063)
        current = current[1,1]
      elsif current[0,1] =~ /n/ix && current != "ny"
        # n followed by anything other than aiueo or y (nya etc. should be left alone)
        result << jp_unicode(two[:nn])
        current = current[1..current.length()-1]
      end
    when 3
      s = three[ch]
      if !s.nil?()
        # Three char translation works
        result << jp_unicode(s)
        current = ""
      end
    when 4
      s = four[ch]
      if !s.nil?()
        # Four char translation works
        result << jp_unicode(s)
        current = ""
      end
    end
    # Look for the hiragana digraphs
    if current =~ /^(k|sh|ch|n|h|m|r|g|j|b|p)(ya|yu|yo)$/ix
      first = ($1 + "i").downcase()
      second = $2.downcase()
      result << jp_unicode(two[first.to_sym()]) + jp_unicode(digraph2[second.to_sym()])
      current = ""
    elsif current =~ /^j(a|u|o)$/ix
      begin
        second = "y" + $1.downcase()
        result << jp_unicode(two[:ji]) + jp_unicode(digraph2[second.to_sym()])
      rescue
        debug_out("Messed up katakana for [#{first}][#{second}]")
        raise
      end
      current = ""
    elsif current =~ /^(sh|ch|j)(a|u|o)$/
      first = $1 + "i"
      second = "y" + $2
      begin
        result << jp_unicode(three[first.to_sym()]) + jp_unicode(digraph2[second.to_sym()])
      rescue
        debug_out("first=[#{first}] one=[#{one[first.to_sym()]}]")
        debug_out("first=[#{second}] one=[#{digraph2[second.to_sym()]}]")
      end
      current = ""
    elsif current =~ /^(ja|ju|jo)$/
      second = $1.downcase()
      debug_out("current=[#{current}] second=[#{second}] ")
      ss = second.sub(/j/, "y")
      debug_out("current=[#{current}] second=[#{second}] ss=[#{ss}]")
      result << jp_unicode(two[:ji]) + jp_unicode(digraph2[ss.to_sym()])
    end

    if current.length() >= 5
      $stderr.puts("HIRAGANA: BROKEN at #{pos} trying to handle [#{current}] in [#{text}]")
      exit(1)
    end
  }

  if current.length() == 1
    if current == "n"
      # Handle stray final "n"
      result << jp_unicode(two[:nn])
      current = ""
    else
      ch = current.downcase().to_sym()
      s = one[ch]
      if !s.nil?()
        # Single char translation works
        result << jp_unicode(s)
        current = ""
      elsif current =~ /^\s*$/
        result << current
        current = ""
      elsif current =~ /[^[:alnum:]]/
        result << current
        current = ""
      end
    end
  end

  raise "Stray trailing hiragana: [#{current}] in [#{text}]" unless current.empty?()

  return result
end

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

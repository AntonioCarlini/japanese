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
    :nn => 0x3093,
    # Alternatives below here
    :ji => 0x3058,
    :hu => 0x3075,
  }
  three = { :shi => 0x3057, :chi => 0x3061, :tsu => 0x3064 }
  digraph2 = { :ya => 0x3083, :yu => 0x3085, :yo => 0x3087 }

  result = ""
  current = ""
  pos = 0
  embed_html = false
  text.chars() {
    |c|
    pos += 1
    current += c
    ch = current.downcase().to_sym()
    if current =~ /^[0-9]$/
      result << current
      current = ""
      next
    elsif current == "<"
      result << current
      embed_html = true
      current = ""
      next
    elsif embed_html
      result << current
      embed_html = false if current == ">"
      current = ""
      next
    end
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

    if current.length() >= 4
      puts("HIRAGANA: BROKEN at #{pos} trying to handle [#{current}] in [#{text}]")
      exit
    end
  }
  return result
end

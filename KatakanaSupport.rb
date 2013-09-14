#!/usr/bin/ruby -w

$LOAD_PATH << File.dirname(__FILE__)

require 'DebugSupport.rb'
require 'UnicodeSupport.rb'

def convert_to_katakana(text)
  one = {
    :a  => 0x30a2, :i =>  0x30a4, :u =>  0x30a6, :e  => 0x30a8, :o  => 0x30aa,
    :","  => 0x3001, :"." =>  0x3002, "[".to_sym() =>  0x300c, :"]"  => 0x300d,
    :"-" => 0x30FC
  }
  two = {
    :ka => 0x30ab, :ki => 0x30ad, :ku => 0x30af, :ke => 0x30b1, :ko => 0x30b3,
    :ga => 0x30ac, :gi => 0x30ae, :gu => 0x30b0, :ge => 0x30b2, :go => 0x30b4,
    :sa => 0x30b5, :si => 0x30b7, :su => 0x30b9, :se => 0x30bb, :so => 0x30bd,
    :za => 0x30b6, :ji => 0x30b8, :zu => 0x30ba, :ze => 0x30bc, :zo => 0x30be,
    :ta => 0x30bf, :ti => 0x30c1, :tu => 0x30c4, :te => 0x30c6, :to => 0x30c8,
    :da => 0x30c0, :di => 0x30c2, :du => 0x30c5, :de => 0x30c7, :do => 0x30c9,
    :na => 0x30ca, :ni => 0x30cb, :nu => 0x30cc, :ne => 0x30cd, :no => 0x30ce,
    :ha => 0x30cf, :hi => 0x30d2, :fu => 0x30d5, :he => 0x30d8, :ho => 0x30db,
    :ba => 0x30d0, :bi => 0x30d3, :bu => 0x30d6, :be => 0x30d9, :bo => 0x30dc,
    :pa => 0x30d1, :pi => 0x30d4, :pu => 0x30d7, :pe => 0x30da, :po => 0x30dd,
    :ma => 0x30de, :mi => 0x30df, :mu => 0x30e0, :me => 0x30e1, :mo => 0x30e2,
    :ya => 0x30e4,                :yu => 0x30e6,                :yo => 0x30e8,
    :ra => 0x30e9, :ri => 0x30ea, :ru => 0x30eb, :re => 0x30ec, :ro => 0x30ed,
    :wa => 0x30ef, :wi => 0x30f0,                :we => 0x30f1, :wo => 0x30f2,
    :nn => 0x30f3,
    # Alternatives below here
    :ji => 0x30b8,
    :hu => 0x30d5,
    :shi => 0x30b7, :chi => 0x30c1
  }
  three = { :shi => 0x30b7, :chi => 0x30c1, :tsu => 0x30c4 }
  digraph2 = { :ya => 0x30e3, :yu => 0x30e5, :yo => 0x30e7 }

  result = ""
  current = ""
  pos = 0
  text.chars() {
    |c|
    pos += 1
    current += c
    ch = current.downcase().to_sym()
    if current =~ /^[0-9]$/
      result << current
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
      begin
        result << jp_unicode(two[first.to_sym()]) + jp_unicode(digraph2[second.to_sym()])
      rescue
        debug_out("Messed up katakana for [#{first}][#{second}]")
        raise
      end
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
    elsif current =~ /^(sh|ch|j|z)(a|u|o)$/ix
      first = ($1 + "i").downcase()
      second = ("y" + $2).downcase()
      begin
        result << jp_unicode(three[first.to_sym()]) + jp_unicode(digraph2[second.to_sym()])
      rescue
        debug_out("first=[#{first}] one=[#{one[first.to_sym()]}]")
        debug_out("first=[#{second}] one=[#{digraph2[second.to_sym()]}]")
      end
      current = ""
    end

    if current.length() >= 4
      puts("KATAKANA: BROKEN at #{pos} trying to handle [#{current}]")
      exit
    end
  }
  return result
end

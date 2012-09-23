#!/usr/bin/ruby -w

def debug_out(text)
  #$stderr.puts(text)
end

def jp_unicode(x)
  begin
    return "&#x#{x.to_s(16)};"
  rescue
    debug_out("Messed up for [#{x}] class #{x.class}")
    raise
  end
end


# :tu => 3063
# :vu => 3093
# small :a => 3041, :i => 3043, :u => 3045, :e => 3047, :o => 3049

# :ji == :zi or :di
# :shi (:si), :chi (:ti), :tsu (:tu)

# small-tsu
# reduplicates
# reduplicates and unvoices


def convert_to_kanji(text)
  kanji = {
    :hon => 0x672c, :watashi => 0x79c1,
    :chiga => 0x9055, :i => 0x884c, :ku => 0x6765, # reconsider
    :kae => 0x5e30, # reconsider
    :samui => 0x5bd2,
    :arinashi => 0x6709, # possess
    :namae => 0x540d, :utsuru => 0x6620,
    :yonkaku => 0x753b, # check
    :ookii => 0x5927,
    :manabu => 0x5b66,
    :ichi => 0x4e00, :ni => 0x4e8c, :san => 0x4e09, :yon => 0x56db, :go => 0x4e94,
    :roku => 0x516d, :nana => 0x4e03, :hachi => 0x516b, :kyuu => 0x4e5d, :juu => 0x5341
  }

  result = ""
  sep = ""
  text.split(/[^a-zA-Z]/).each() {
    |word|
    if word.empty?()
      next
    elsif word !~ /[a-zA-Z]+/
      result += sep + word
      sep = " "
    else
      code = kanji[word.downcase().to_sym()]
      if code.nil?()
        result += sep + "!!UNKNOWN KANJI [#{word}]!!"
        sep = " "
      else
        result += sep + jp_unicode(code)
        sep = " "
      end
    end
  }
  return result
end

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
    :ji => 0x3058
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
    if current =~ /^(k|sh|ch|n|h|m|r|g|j|b|p)(ya|yu|yo)$/
      first = ($1 + "i").downcase()
      second = $2.downcase()
      result << jp_unicode(two[first.to_sym()]) + jp_unicode(digraph2[second.to_sym()])
      current = ""
      elsif current =~ /^(sh|ch)(a|u|o)$/
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
      puts("BROKEN at #{pos} trying to handle [#{current}]")
      exit
    end
  }
  return result
end

def convert_to_katakana(text)
  one = {
    :a  => 0x30a2, :i =>  0x30a4, :u =>  0x30a6, :e  => 0x30a8, :o  => 0x30aa,
    :","  => 0x3001, :"." =>  0x3002, "[".to_sym() =>  0x300c, :"]"  => 0x300d
  }
  two = {
    :ka => 0x30ab, :ki => 0x30ad, :ku => 0x30af, :ke => 0x3051, :ko => 0x3053,
    :ga => 0x30ac, :gi => 0x30ae, :gu => 0x30b0, :ge => 0x30b2, :go => 0x30b4,
    :sa => 0x30b5, :si => 0x30b7, :su => 0x30b9, :se => 0x30bb, :so => 0x30bd,
    :za => 0x30b6, :ji => 0x30b8, :zu => 0x30ba, :ze => 0x30bc, :zo => 0x30be,
    :ta => 0x30bf, :ti => 0x30c1, :tu => 0x30c4, :te => 0x30c6, :to => 0x30c8,
    :da => 0x30c0, :di => 0x30c2, :du => 0x30c5, :de => 0x30c7, :do => 0x30c9,
    :na => 0x30ca, :ni => 0x30cb, :nu => 0x30cc, :ne => 0x30cd, :no => 0x30ce,
    :ha => 0x30cf, :hi => 0x30d2, :hu => 0x30d5, :he => 0x30d8, :ho => 0x30db,
    :ba => 0x30d0, :bi => 0x30d3, :bu => 0x30d6, :be => 0x30d9, :bo => 0x30dc,
    :pa => 0x30d1, :pi => 0x30d4, :pu => 0x30d7, :pe => 0x30da, :po => 0x30dd,
    :ma => 0x30de, :mi => 0x30df, :mu => 0x30e0, :me => 0x30e1, :mo => 0x30e2,
    :ya => 0x30e4,                :yu => 0x30e6,                :yo => 0x30e8,
    :ra => 0x30e9, :ri => 0x30ea, :ru => 0x30eb, :re => 0x30ec, :ro => 0x30ed,
    :wa => 0x30ef, :wi => 0x30f0,                :we => 0x30f1, :wo => 0x30f2,
    :nn => 0x30f3,
    # Alternatives below here
    :ji => 0x30b8,
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
    if current =~ /^(k|sh|ch|n|h|m|r|g|j|b|p)(ya|yu|yo)$/
      first = ($1 + "i").downcase()
      second = $2.downcase()
      begin
        result << jp_unicode(two[first.to_sym()]) + jp_unicode(digraph2[second.to_sym()])
      rescue
        debug_out("Messed up katakana for [#{first}][#{second}]")
        raise
      end
      current = ""
      elsif current =~ /^(sh|ch)(a|u|o)$/
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
      puts("BROKEN at #{pos} trying to handle [#{current}]")
      exit
    end
  }
  return result
end

def display(state, text)
  case state
  when NORMAL     then return text
  when HIRAGANA   then return convert_to_hiragana(text)
  when KATAKANA   then return convert_to_katakana(text)
  when KANJI      then return convert_to_kanji(text)
  else                 raise("No #{state} support yet")
  end
end

if ARGV.empty?()
  puts("Usage: #{File.basename($0)} text-to-translate\n")
  exit
end

file = ARGV.shift()
if ARGV.empty?()
  output = file.sub(/\.jhtml$/, ".html")
else
  output = ARGV.shift()
end

raise("Input file unsuitable") if output == file

op = File.open(output, "w")

NORMAL = 1
HIRAGANA = 2
KATAKANA = 3
KANJI = 4

# Start with the state stack at NORMAL
state_stack = []
state = NORMAL

line_num = 0
File.open(file, "r").each_line() {
  |line, index|
  line.chomp!()
  line_num += 1
  to_handle = line
  debug_out("state is #{state}, line is [#{to_handle}]")
  until to_handle.empty?()
    if to_handle =~ %r{^(.*?)(<nihongo>|<hiragana>|<katakana>|<kanji>|</nihongo>|</hiragana>|</katakana>|</kanji>)(.*)$}
      prefix = $1
      style = $2
      suffix = $3
      debug_out("CHANGE state=#{state} prefix=#{prefix} style=#{style} suffix=#{suffix}")

      state_stack << state unless style[0,2] == "</"

      case style
      when "<hiragana>", "<nihongo>"
        op.print(display(state, prefix))
        state = HIRAGANA
        to_handle = suffix
      when "<katakana>"
        op.print(display(state, prefix))
        state = KATAKANA
        to_handle = suffix
      when "<kanji>"
        op.print(display(state, prefix))
        state = KANJI
        to_handle = suffix
      when "</hiragana>", "</nihongo>"
        raise("Closing #{style} in state #{state}") if state != HIRAGANA
        op.print(display(state, prefix))
        to_handle = suffix
      when "</katakana>"
        raise("Closing #{style} in state #{state}") if state != KATAKANA
        op.print(display(state, prefix))
        to_handle = suffix
      when "</kanji>"
        raise("Closing #{style} in state #{state}") if state != KANJI
        op.print(display(state, prefix))
        to_handle = suffix
      end
      state = state_stack.pop() if style[0,2] == "</"

      debug_out("CHANGE end-state=#{state} stack-state=#{state_stack.last()}")
    else
      op.print(display(state, to_handle))
      to_handle = ""
    end
  end
  op.puts()
}

raise("Missing </nihongo> somewhere") unless state == NORMAL

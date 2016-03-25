#!/usr/bin/ruby -w

$LOAD_PATH << File.dirname(__FILE__)

require 'DataKanji.rb'
require 'DataRefs.rb'
require 'DebugSupport.rb'
require 'HiraganaSupport.rb'
require 'Kanji.rb'
require 'KanjiSupport.rb'
require 'KatakanaSupport.rb'
require 'RefsSupport.rb'
require 'UnicodeSupport.rb'

# Reads a LibreOffice Write document exported as HTML and converts to a form suitable
# for inclusion in a JHTML file.

# Now build a hash of unicode => kanji
$unicode_2_kanji = {}

# Converts a code such as 12367 in "&#12367;" into hiragana, katakana or kanji.
# Hiragana: 12352 - 12447
# Katakana: 12449 - 12539
def code_to_jhtml(code)
  c = convert_unicode_to_hiragana_jhtml(code)
  return "@HI{{#{c}}}" unless c.nil?()

  if code >= 12449 && code <= 12539
    return "@KT{{}}"
  end

  k = $unicode_2_kanji[code]
  unless k.nil?()
    return "@KJ{{#{k.english()[0]}}}"
  end

  return "@UNK{{#{code}}}"
end

file = ARGV.shift()

kanji_data_file = "/home/antonioc/tmp/japanese/kanji.data"

# Read the Heisig kanji from the kanji data file.
kanji_data = DataKanji.create_from_file(kanji_data_file)


kanji_data.kanji().each() {
  |k|
  $unicode_2_kanji[k.unicode()] = k
}

puts("u2k.size = #{$unicode_2_kanji.size()}")
puts("u2k.unicode.class = #{$unicode_2_kanji[0x65e5].unicode.class}")

# Read the file looking for text in this sort of arrangment
# <P STYLE="margin-bottom: 0cm"><FONT FACE="SimSun"><FONT SIZE=2 STYLE="font-size: 10pt"><SPAN LANG="ja-JP">
# ...
# </SPAN></FONT></FONT></P>

qQ = '"[^"]+"'  # a quoted string with any contents
inE = "[^>]+"   # arbitrary contents within an HTML element
prefix = "<P STYLE=#{qQ}><FONT FACE=#{qQ}><FONT SIZE=#{inE}><SPAN LANG=#{inE}>"
suffix = "</SPAN></FONT></FONT></P>".gsub(%r{/}, '\/')

text = IO.read(file)
text = text.force_encoding("ISO-8859-1") if RUBY_VERSION !~ /^0.|^1.[0-8]/ 

text.scan(%r{#{prefix}(.*?)#{suffix}}im) {
  |jp|
  str = jp[0].gsub(%r{<SPAN STYLE#{inE}>}, "").gsub(%r{<\/SPAN>}, "")
  str.sub!(%r{<FONT COLOR=#{qQ}><U>}, "<strong>")
  str.sub!(%r{<\/U><\/FONT>}, "</strong>")

  # Could be kanji or kana ...
  output = str.gsub(/&#(\d+);/) {
    |ch|
    code = $1.to_i()
    "#{code_to_jhtml(code)}"
  }
  
  again = true
  while (again)
    hi = output.gsub!(/@HI\{\{([^\}]+)\}\}@HI\{\{([^\}]+)\}\}/, '@HI{{\1\2}}')
    kt = output.gsub!(/@KT\{\{([^\}]+)\}\}@KT\{\{([^\}]+)\}\}/, '@KT{{\1\2}}')
    kj = output.gsub!(/@KJ\{\{([^\}]+)\}\}@KJ\{\{([^\}]+)\}\}/, '@KJ{{\1^\2}}')
    again = (!hi.nil?()) || (!kt.nil?()) || (!kj.nil?())
  end

  # Wrong but temporary - should only be done within @HI{{}} and @KT{{}}
  output.gsub!(/@(HI|KT)\{\{(.*?)\}\}/) {
    |x|
    style = $1
    text = $2
#    $stderr.puts("Looking at [#{style}] [#{text}]")
    text.gsub!(/(sh|ch)ixy(a|u|o)/,  '\1\2')           # must be before 2-char codes!
    text.gsub!(/(k|n|h|m|r|g|b|p)ix(ya|yu|yo)/, '\1\2')
    text.gsub!(/jixy(a|u|o)/,  'j\1')
#    $stderr.puts("result is [#{style}] [#{text}]")
    "@#{style}{{#{text}}}"
  }
  puts("#{output}")
}

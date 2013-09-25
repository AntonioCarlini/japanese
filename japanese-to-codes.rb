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

NORMAL = 1
HIRAGANA = 2
KATAKANA = 3
KANJI = 4

def display(state, text)
  case state
  when NORMAL     then return text
  when HIRAGANA   then return convert_to_hiragana(text)
  when KATAKANA   then return convert_to_katakana(text)
  when KANJI      then return convert_to_kanji(text)
  else                 raise("No support yet for state [#{state}]")
  end
end

def handle_cli(file, op)
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
  return file, op
end

def processing()

  file,op = handle_cli(file, op)

  # Start with the state stack at NORMAL
  state_stack = []
  state = NORMAL

  # Read the file and process includes to an arbirary depth
  file_data = IO.read(file)
  include_seen = false
  begin
    include_seen = false
    file_data.gsub!(/@include\{\{\"([^\}]+)\"\}\}/m) {
      |what|
      include_seen = true
      filename = $1
      result = IO.read(filename)
      debug_out("inserting for:[#{result}]")
      result
    }
  end while include_seen
  
  line_num = 0
  file_data.each_line() {
    |line, index|
    line.chomp!()
    line_num += 1
    to_handle = line
    debug_out("Line #{line_num}")
    debug_out("state is #{state}, line is [#{to_handle}]")
    until to_handle.empty?()
      orig_to_handle = to_handle.dup()

      # Handle fixed conversions first (all of the form @XX{{}} where XX is alphanumeric and case sensitive)
      to_handle.gsub!(/@([a-zA-Z0-9]{1,9})\{\{(\w*)\}\}/) {
        |type|
        style = $1
        brkt = $2
        case $1
        when /masustem/ then "<sub><del>#{convert_to_hiragana('masu')}</del></sub>"
        when /V1/   then "V<sub>1</sub>"
        when /V2/   then "V<sub>2</sub>"
        when /V3/   then "V<sub>3</sub>"
        when /V4/   then "V<sub>4</sub>"
        when /V5/   then "V<sub>5</sub>"
        when /V6/   then "V<sub>#{convert_to_hiragana('te')}</sub>"
        when /V7/   then "V<sub>#{convert_to_hiragana('ta')}</sub>"
        when /1D/   then "#{convert_to_kanji('ichi^dan')}"
        when /5D/   then "#{convert_to_kanji('go^dan')}"
        when /Nplace/   then "N<sub>place</sub>"
        when /N\d?/  then
          sub = style[1..-1] # lose first character
          string = "N"
          string += "<sub>#{sub}</sub>" unless sub.nil?() || sub.empty?()
          string += "(#{brkt})" unless brkt.nil?() || brkt.empty?()
          string

        when /S\d?/  then
          sub = style[1..-1] # lose first character
          string = "S<sub>#{sub}</sub>"
          string += "(#{brkt})" unless brkt.nil?() || brkt.empty?()
          string

          # forms based on those used in Nihongo So-Matome
        when /^S$/         then "S"                                            # sentence (either plain or polite)
        when /Splain/      then "S<sub>plain</sub>"                            # plain form sentence
        when /Vplain/      then "V<sub>plain</sub>"                            # plain form
        when /Vru/         then "V#{convert_to_hiragana('ru')}"                # dictionary form
        when /Vnai/        then "V#{convert_to_hiragana('nai')}"               # negative
        when /Vnaistem/    then "V<del>#{convert_to_hiragana('nai')}</del>"    # negative stem
        when /Vru/         then "V#{convert_to_hiragana('ru')}"                # dictionary form
        when /Vmasu/       then "V#{convert_to_hiragana('masu')}"              # masu form
        when /Vmasustem/   then "V<del>#{convert_to_hiragana('masu')}</del>"   # masu stem
        when /Vnai/        then "V#{convert_to_hiragana('nai')}"               # negative
        when /Vte/         then "V#{convert_to_hiragana('te')}"                # te-form
        when /Vta/         then "V#{convert_to_hiragana('ta')}"                # past
        when /Vteiru/      then "V#{convert_to_hiragana('teiru')}"             # te iru form
        when /Vba/         then "V#{convert_to_hiragana('ba')}"                # ba (conditional)
        when /Vyou/        then "V#{convert_to_hiragana('you')}"               # volitional
        when /Vreru/       then "V#{convert_to_hiragana('reru')}"              # potential
        when /Vrareru/     then "V#{convert_to_hiragana('rareru')}"            # passive
        when /Vsaseru/     then "V#{convert_to_hiragana('saseru')}"            # causative
        when /^Ai$/        then "A-#{convert_to_hiragana('i')}"                # i-adjective
        when /Aistem/      then "A-<del>#{convert_to_hiragana('i')}</del>"     # i-adjective stem
        when /^Ana$/       then "A-#{convert_to_hiragana('na')}"               # na-adjective
        when /Anastem/     then "A-<del>#{convert_to_hiragana('na')}</del>"    # na-adjective stem
        when /^(HI|KT|KJ|REF)$/
          # These codes should be left alone ... they'll be handled below
          string = "@#{style}{{#{brkt}}}"
        else
          debug_out("Line: #{line_num}: Unknown {{}} code: [#{$1}]")
          "&lt;UNKNOWN @code [#{style}]&gt;"
        end
      }
      
      to_handle.gsub!(/@REF\{\{(.*?)\}\}/) {
        |m|
        res = ""
        ident = m.sub(/@REF\{\{(.*)\}\}/, '\1')
        ref = convert_ref(ident)
        if ref.nil?()
          res = "&lt;UNKNOWN REF [#{ident}]&gt;"
        else
          alt = ref.alternate()
          res = "<span title=\"#{alt}\"> "unless alt.nil?() || alt.empty?()
          res += ref.text()
          res += "</span> "unless alt.nil?() || alt.empty?()
        end
        res
      }

      # Handle conversions that may contain embedded conversions
      # Do NOT assume that a valid conversion must be on one line
      # On seeing a start of conversion, behave as for <hiragana> etc.
      # Do not allow mixing of new style and old style
      if to_handle =~ %r{^([^\{\}]*?)(@([a-zA-Z0-9]{2})\{\{|\}\})(.*)$}
        prefix = $1
        full_match = $2
        action = $3
        suffix = $4

        # If a new state has been declared, save the old state
        state_stack << state unless action.nil?()

        debug_out("CHANGE state=#{state} prefix=[#{prefix}] [#{full_match}] [#{action}]  suffix=#{suffix}")

        # Display the prefix according to the old state and process the suffix next time around
        op.print(display(state, prefix))
        to_handle = suffix

        # Select the new state according to the action
        case action
        when /^HI$/   then state = HIRAGANA
        when /^KT$/   then state = KATAKANA
        when /^KJ$/   then state = KANJI
        when nil      then state = state_stack.pop() if action.nil?()
        end

        debug_out("CHANGE end-state=#{state} stack-state=#{state_stack.last()}")
      end

      debug_out("Is [#{to_handle}]")

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
          raise("Line #{line_num}: Closing #{style} in state #{state}") if state != HIRAGANA
          op.print(display(state, prefix))
          to_handle = suffix
        when "</katakana>"
          raise("Line #{line_num}: Closing #{style} in state #{state}") if state != KATAKANA
          op.print(display(state, prefix))
          to_handle = suffix
        when "</kanji>"
          raise("Line #{line_num}: Closing #{style} in state #{state}") if state != KANJI
          op.print(display(state, prefix))
          to_handle = suffix
        end
        state = state_stack.pop() if style[0,2] == "</"

        debug_out("CHANGE end-state=#{state} stack-state=#{state_stack.last()}")
      elsif to_handle !~ /\}\}/
        op.print(display(state, to_handle))
        to_handle = ""
      end

      if to_handle == orig_to_handle
        raise("on line #{line_num} to_handle unchanged: [#{to_handle}]")
      end
    end
    op.puts()
  }

  raise("Missing </nihongo> somewhere") unless state == NORMAL
end

# Wrap everything in a begin/end to facilitate error handling
begin
  processing()
end

#!/usr/bin/ruby -w

$LOAD_PATH << File.dirname(__FILE__)

require 'DebugSupport.rb'
require 'HiraganaSupport.rb'
require 'KanjiSupport.rb'
require 'KatakanaSupport.rb'
require 'ProcessingError.rb'
require 'RadicalSupport.rb'
require 'RefsSupport.rb'

require 'singleton'

OPENING_BRACKETS = Regexp.escape("{{")
CLOSING_BRACKETS = Regexp.escape("}}")

OPENING_REGEXP = "@\\w{1,15}#{OPENING_BRACKETS}"
CLOSING_REGEXP = "#{CLOSING_BRACKETS}"

# A class to hold text that may require further processing.
class Text

  attr_reader :text
  attr_reader :operation

  def initialize(text)
    @text = text.dup()
    @operation = nil
  end

  def text?()
    return true;
  end

  def op?()
    return false;
  end

  def processed?()
    return false;
  end

  def display()
    text = @text[0..30].tr("\n", "_")
    text << "..." if @text.size() > 30
    return "Text:        #{text}"
  end
end

# A class to hold text that requires no further processing.
class DoneText

  attr_reader :text
  attr_reader :operation

  def initialize(text)
    @text = text.dup()
    @operation = nil
  end

  def text?()
    return true;
  end

  def op?()
    return false;
  end

  def processed?()
    return true;
  end

  def display()
    text = @text[0..30].tr("\n", "_")
    text << "..." if @text.size() > 30
    return "DoneText:    #{text}"
  end
end

# A class to describe an operation
class Operation

  attr_reader :code
  attr_reader :operation
  attr_reader :text

  def initialize(operation, code)
    @text = nil
    @operation = operation
    @code = code
  end

  def text?()
    return false;
  end

  def op?()
    return true;
  end

  def processed?()
    return false;
  end

  def display()
    return "Operation:   #{@operation}"
  end
end

# An object to hold DIV settings
class Divs

  # names is an array of DIV names
  def initialize(names)
    @divs = names
    @pos = @divs.size() + 1
    @div_used = false
  end

  # Fetches the next DIV name
  def next()
    @div_used = true
    @pos = @pos + 1
    @pos = 0 if @pos >= @divs.size()
    return @divs[@pos]
  end

  # Indicates that next() has been called
  def div_used?()
    return @div_used
  end
end

# An object to hold global state
class State
  attr_accessor :divs

  include Singleton
  def initialize()
    @divs = nil
  end

  def divs_start(names)
    raise("DIVs within DIVs") unless @divs.nil?()
    @divs = Divs.new(names)
  end

  def divs_end()
    @divs = nil
  end

  def divs_next()
    return @divs.next()
  end

  def divs_active?()
    return false if @divs.nil?()
    @divs.div_used?()
  end
end

=begin
Given:
  some-text @HI{{hiragana @KJ{{kanji}} more-hiragana @KT{{katakana}} even-more-hiragana}} trailing-text

Procesing:
  stack << text: some-text
  stack << op: @HI
  stack << text: hiragana
  stack << op: @KJ
  stack << text: kanji

Now the "}}" closing the kanji op is seen. pop the stack, see text, save text, repeat until op, call op handler.
Now stack looks like this:

  stack << text: some-text
  stack << op: @HI
  stack << text: hiragana
  stack << done-text: @KJ{{kanji}}
  
Continue processing:

  stack << text: some-text
  stack << op: @HI
  stack << text: hiragana
  stack << done-text: @KJ{{kanji}}
  stack << more-hiragana
  stack << op: @KT
  stack << text: katakana

Now the "}}" closing the katakana op is seen. As before, finalised text is pushed

  stack << text: some-text
  stack << op: @HI
  stack << text: hiragana
  stack << done-text: @KJ{{kanji}}
  stack << more-hiragana
  stack << done-text: @KT{{katakana}}

Continue processing:

  stack << text: some-text
  stack << op: @HI
  stack << text: hiragana
  stack << done-text: @KJ{{kanji}}
  stack << more-hiragana
  stack << done-text: @KT{{katakana}}
  stack << text: even-more-hiragana

Now the "}}" is seen that closes the hiragana op. As before, pop all text/done-text until an op is seen. This mini-stack is 
passed to the op handler and is processed to produce

  stack << text: some-text
  stack << done-text: @HI{{ .... }}

Continuing to process:

  stack << text: some-text
  stack << done-text: @HI{{ .... }}
  stack << text: trailing-text

Now the end of the file is reached. There should be no ops on the stack.

To optimise:

 - if the stack is empty, do not push text, simply output it.
 - if, after processing an op, the stack is empty, do not push done-text onto it, simply output it

=end

$command_to_op = {
  "MK" => :process_marker,
  "HI" => :process_hiragana,
  "KJ" => :process_kanji,
  "KT" => :process_katakana,
  "FG" => :process_furigana,
  "EM" => :process_emphasis,
  "GRMIDX" => :process_grammar_index,
  "LIT" => :process_literal,
  "masustem" => :process_empty_code,
  "V1" => :process_empty_code,
  "V2" => :process_empty_code,
  "V3" => :process_empty_code,
  "V4" => :process_empty_code,
  "V5" => :process_empty_code,
  "V6" => :process_empty_code,
  "V7" => :process_empty_code,
  "1D" => :process_empty_code,
  "5D" => :process_empty_code,
  "Nplace" => :process_empty_code,
  "S" => :process_empty_code,
  "Splain" => :process_empty_code,
  "Vplain" => :process_empty_code,
  "Vru" => :process_empty_code,
  "Vnai" => :process_empty_code,
  "Vnaide" => :process_empty_code,
  "Vnaistem" => :process_empty_code,
  "Vzu" => :process_empty_code,
  "Vnu" => :process_empty_code,
  "Vmasu" => :process_empty_code,
  "Vmasustem" => :process_empty_code,
  "Vte" => :process_empty_code,
  "Vde" => :process_empty_code,
  "Vteiru" => :process_empty_code,
  "Vdeiru" => :process_empty_code,
  "Vta" => :process_empty_code,
  "Vtara" => :process_empty_code,
  "Vba" => :process_empty_code,
  "Vyou" => :process_empty_code,
  "Vreru" => :process_empty_code,
  "Vrenai" => :process_empty_code,
  "Vrareru" => :process_empty_code,
  "Vsaseru" => :process_empty_code,
  "Vsasete" => :process_empty_code,
  "Vsaserareru" => :process_empty_code,
  "NS" => :process_empty_code,
  "NPhr" => :process_empty_code,
  "VPhr" => :process_empty_code,
  "Ai" => :process_empty_code,
  "Aistem" => :process_empty_code,
  "Aku" => :process_empty_code,
  "Akute" => :process_empty_code,
  "Ana" => :process_empty_code,
  "Anastem" => :process_empty_code,
  "MIDDOT" => :process_empty_code,
  "BGRNDSTART" => :process_background_start,
  "BGRND" => :process_background_insert,
  "BGRNDEND" => :process_background_end,
  "SHIME" => :process_empty_code,
  "JTILDE" => :process_empty_code,
  "JDOTS3" => :process_empty_code,
  "JDOTS6" => :process_empty_code,
  "KA" => :process_empty_code,    # small ka
  "KE" => :process_empty_code,    # small ke
  "KOME" => :process_empty_code,
  "JSTAR" => :process_empty_code,
  "TICK" => :process_empty_code,
  "QNTF" => :process_empty_code,
  "QW" => :process_empty_code,
  "CTR" => :process_empty_code,
  "ADV" => :process_empty_code,
  "PRT" => :process_empty_code,
  "RELC" => :process_empty_code,
  "RD" => :process_radical,
  "OPTTEXT" => :process_optional_text,
  "FORMATION" => :process_formation,
  "HIMITSU" => :process_empty_code,
  "VERPEND" => :process_empty_code,
}

def process_at_commands(text, data_dir, filename)

  processing_errors = []  # Collect errors instead of exiting immediately
  
  # REF is special and must be processed before anything else.
  # Recursive REFs make no sense so do not cater for them.
  begin
    text.gsub!(/@(REF|UCREF)\{\{([^\}]+)\}\}/m) {
      |what|
      unchecked = ($1 == "UCREF")
      ref = $2
      debug_out("inserting for REF:[#{ref}]")
      transform_ref(ref, data_dir, unchecked)
    }
  end
  
  stack = []
  answer = ""

  to_handle = text

  if to_handle !~ /#{OPENING_REGEXP}/ixm
    debug_out("No command found")    
    answer << to_handle
    to_handle = nil
  end

  while !to_handle.nil?() && !to_handle.empty?()
    m = /(#{OPENING_REGEXP}|#{CLOSING_REGEXP})/ixm.match(to_handle)
    if !m.nil?()
      text = m.pre_match()
      current = m[0]
      to_handle = m.post_match().dup()
      debug_out("Found something to process")    
      
      if stack.empty?()
        answer << text
      else
        stack << Text.new(text)
      end

      if current =~ /#{CLOSING_REGEXP}/
        # Build the mini stack by working backwards through the stack until
        # an operation is found.
        mini_stack = []
        object = nil
        while !stack.empty?()
          object = stack.pop()
          if object.text()
            mini_stack.unshift(object) # This element belongs _before_ the element just added
          else
            break
          end
        end
        # Call the op processor - if there isn't one then this is a bug
        raise("No object on the stack with current [#{text}#{current}] to handle [#{to_handle}]") if object.nil?()
        op = object.operation()
        raise("Object has no operation") if op.nil?()
        begin
          result = send(op, mini_stack, object.code())
        rescue NoMethodError => e
          # This is probably a missing require or similar
          raise e
        rescue ProcessingError => e
            $stderr.puts("Non-fatal error: #{e.message}")
            processing_errors << e  # Store the error so we can decide what to do later
        rescue => e
          $stderr.puts(e)
          $stderr.puts("Fatal error processing <#{op}> near line: [#{to_handle.split(/\n|\r\n/)[0]}]")
          $stderr.puts("Fatal data: [#{to_handle[0..30]}\n]")
          $stderr.puts("in source [#{filename}]\n")
          $stderr.puts(e.backtrace())
          raise e
        end
        if stack.empty?()
          answer << puts_result(result)
        else
          stack << result
          stack.flatten!()
        end

      else
        if current =~ /@(.*)#{OPENING_BRACKETS}/
          command = $1
          if command =~ /^(N|V|S)(\d*)$/
            stack << Operation.new(:process_NSV, command)
          else
            op = $command_to_op[command]
            if op.nil?()
              debug_out("No OP found for [#{command}] in [#{current}]") # should be a raise
            else
              stack << Operation.new(op, command)
            end
          end
        else
          raise("Badly formed command: [#{current}]")
        end
      end
    else
      # No match. This must be a sequence of trailing text that will never be processed
      debug_out("Finished handling text")
      answer << to_handle
      break
    end
  end

  unless stack.empty?()
    dump_stack(stack)
    raise("Non-empty stack")
  end

  unless processing_errors.empty?
    raise "\nEncountered #{processing_errors.size} errors during processing."
    exit 1
  end

  return answer
end

#+
# Utility functions
#-

# Given some text, substitute @REF{{}} statements as required. 
def transform_ref(text, data_dir, unchecked)
  res = ""
  ref = convert_ref(text, data_dir)
  if ref.nil?()
    res = "&lt;UNKNOWN REF [#{text}]&gt;"
  else
    alt = ref.alternate()
    res = "<span title=\"#{alt}\"> "unless alt.nil?() || alt.empty?()
    res << jp_unicode(0x203B) if unchecked
    res << ref.text()
    res << "</span>" unless alt.nil?() || alt.empty?()
  end
  return res
end

# Debug function used to display the current state of the stack
def dump_stack(orig_stack)
  stack = orig_stack.dup()
  while !stack.empty?()
    item = stack.pop()
    diagnostic_out("#{item.display()}")
  end
end

# Ensures returns the supplied text modified to be marked as a grammatical text.
def mark_as_grammar(text)
  return '<span class="grammar">' + text + '</span>'
end


# Given a stack, concatenates all the text and consolidates it into a single String
def puts_result(stack)
  result = ""
  stack.each() {
    |x|
    raise("Trying to output OP") if x.op?()
    result << x.text()
  }
  return result
end

# Given a stack, concatenates all the text and consolidates it into a single DoneText object, which is returned.
def collapse_result(stack)
  result = ""
  stack.each() {
    |x|
    raise("Found OP in result") if x.op?()
    result << x.text()
  }
  return DoneText.new(puts_result(stack))
end

# Given a stack, concatenates all the text and consolidates it into a single DoneText object.
# This DoneText object is returned as an Array.
def collapse_stack(stack)
  return [ collapse_result(stack) ]
end

#+
# Process functions.
#
# Each function conforms to this api:
#
# func(stack, code)
#  stack - an Array of objects to which this function should be applied in turn
#  code  - a String describing the command (e.g. for @N1{{..}} the String would be N1)
#
#  returns: an Array of objects
#-

# Process all unprocessed text as hiragana
def process_hiragana(stack, unused)
  result = []
  stack.each() {
    |x|
    if x.processed?()
      result << x
    else
      result << DoneText.new(convert_to_hiragana(x.text()))
    end
  }
  return collapse_stack(result)
end

# Process all unprocessed text as kanji
def process_kanji(stack, unused)
  result = []
  stack.each() {
    |x|
    if x.processed?()
      result << x
    else
      result << DoneText.new(convert_to_kanji(x.text()))
    end
  }
  return collapse_stack(result)
end

# Process all unprocessed text as radicals
def process_radical(stack, unused)
  result = []
  stack.each() {
    |x|
    if x.processed?()
      result << x
    else
      result << DoneText.new(convert_to_radical(x.text()))
    end
  }
  return collapse_stack(result)
end

# Process all furigana. Everything up to the first ":" is the text to display
# and everything else is assumed to be the furigana (which is encoded as a title).
# All otherwise unprocessed text is assumed to be hiragana.
def process_furigana(stack, unused)
  display_result = []
  result = []
  in_display = true
  stack.each() {
    |x|
    if x.processed?()
      result << x
    else
      text = x.text()
      # If the first ":" is seen, switch from display to tooltip
      if in_display && text =~ /:/
        pre = $`
        post = $'
        result << DoneText.new(convert_to_hiragana(pre))
        display_result = result
        result = [ DoneText.new(convert_to_hiragana(post)) ]
        in_display = false
      else
        result << DoneText.new(convert_to_hiragana(x.text()))
      end
    end
  }
  if in_display
    dump_stack(result)
    raise("Failed to specify furigana in @FG")
  end
  tip = "<span title=\"#{collapse_result(result).text()}\">"
  tip << collapse_result(display_result).text()
  tip << "</span>"
  return [ DoneText.new(tip) ]
end

# Process all unprocessed text as katakana
def process_katakana(stack, unused)
  result = []
  stack.each() {
    |x|
    if x.processed?()
      result << x
    else
      result << DoneText.new(convert_to_katakana(x.text()))
    end
  }
  return collapse_stack(result)
end

# Process all unprocessed text as "literal"
# This is used to mark an alternative as a literal translation.
def process_literal(stack, unused)
  result = []
  result << DoneText.new("(lit: ")
  stack.each() {
    |x|
    if x.processed?()
      result << x
    else
      result << DoneText.new(x.text())
    end
  }
  result << DoneText.new(")")
  return collapse_stack(result)
end

# Process all unprocessed text as "optional"
# The current implementation just underlines it for now.
def process_optional_text(stack, unused)
  result = []
  result << DoneText.new("<u>")
  stack.each() {
    |x|
    if x.processed?()
      result << x
    else
      result << DoneText.new(x.text())
    end
  }
  result << DoneText.new("</u>")
  return collapse_stack(result)
end

# Process a formation.
# The current implementation reproduces the original text unchanged.
def process_formation(stack, unused)
  result = []
  stack.each() {
    |x|
    if x.processed?()
      result << x
    else
      result << DoneText.new(x.text())
    end
  }
  return collapse_stack(result)
end


def process_marker(stack, unused)
  return [ DoneText.new("[[MARKER:#{stack.last().text()}]]") ]
end

# Transform text from a command of the form @ABC{{}}
def process_empty_code_helper(code)
        case code
        when /^masustem$/  then mark_as_grammar("<sub><del>#{convert_to_hiragana('masu')}</del></sub>")
        when "V1"          then "V<sub>1</sub>"
        when "V2"          then "V<sub>2</sub>"
        when "V3"          then "V<sub>3</sub>"
        when "V4"          then "V<sub>4</sub>"
        when "V5"          then "V<sub>5</sub>"
        when "V6"          then "V<sub>#{convert_to_hiragana('te')}</sub>"
        when "V7"          then "V<sub>#{convert_to_hiragana('ta')}</sub>"
        when "1D"          then "#{convert_to_kanji('ichi^dan')}"
        when "5D"          then "#{convert_to_kanji('go^dan')}"
        when "Nplace"      then mark_as_grammar("N<sub>place</sub>")
        when "S"           then mark_as_grammar("S")                                            # sentence (either plain or polite)
        when "Splain"      then mark_as_grammar("S<sub>plain</sub>")                            # plain form sentence
        when "Vplain"      then mark_as_grammar("V<sub>plain</sub>")                            # plain form
        when "Vru"         then mark_as_grammar("V#{convert_to_hiragana('ru')}")                # dictionary form
        when "Vnai"        then mark_as_grammar("V#{convert_to_hiragana('nai')}")               # negative
        when "Vnaide"      then mark_as_grammar("V#{convert_to_hiragana('naide')}")             # negative-te-form
        when "Vnaistem"    then mark_as_grammar("V<del>#{convert_to_hiragana('nai')}</del>")    # negative stem
        when "Vzu"         then mark_as_grammar("V#{convert_to_hiragana('zu')}")                # negative zu-form
        when "Vnu"         then mark_as_grammar("V#{convert_to_hiragana('nu')}")                # negative nu-form
        when "Vmasu"       then mark_as_grammar("V#{convert_to_hiragana('masu')}")              # masu form
        when "Vmasustem"   then mark_as_grammar("V<del>#{convert_to_hiragana('masu')}</del>")   # masu stem
        when "Vte"         then mark_as_grammar("V#{convert_to_hiragana('te')}")                # te-form
        when "Vde"         then mark_as_grammar("V#{convert_to_hiragana('de')}")                # te-form for "mu"/"bu"
        when "Vta"         then mark_as_grammar("V#{convert_to_hiragana('ta')}")                # past
        when "Vtara"       then mark_as_grammar("V#{convert_to_hiragana('tara')}")              # ta-conditional
        when "Vteiru"      then mark_as_grammar("V#{convert_to_hiragana('teiru')}")             # te iru form
        when "Vdeiru"      then mark_as_grammar("V#{convert_to_hiragana('deiru')}")             # te iru form for "mu"/"bu"
        when "Vba"         then mark_as_grammar("V#{convert_to_hiragana('ba')}")                # ba (conditional)
        when "Vyou"        then mark_as_grammar("V#{convert_to_hiragana('you')}")               # volitional
        when "Vreru"       then mark_as_grammar("V#{convert_to_hiragana('reru')}")              # potential
        when "Vrenai"      then mark_as_grammar("V#{convert_to_hiragana('renai')}")             # negative potential
        when "Vrareru"     then mark_as_grammar("V#{convert_to_hiragana('rareru')}")            # passive
        when "Vsaseru"     then mark_as_grammar("V#{convert_to_hiragana('saseru')}")            # causative
        when "Vsasete"     then mark_as_grammar("V#{convert_to_hiragana('sasete')}")            # causative-te-form
        when "Vsaserareru" then mark_as_grammar("V#{convert_to_hiragana('saserareru')}")        # causative-passive
        when "NS"          then mark_as_grammar("N<del>#{convert_to_hiragana('suru')}</del>")   # noun-suru without suru
        when "NPhr"        then mark_as_grammar("N-<em>phrase</em>")                            # noun-phrase
        when "VPhr"        then mark_as_grammar("V-<em>phrase</em>")                            # verb-phrase
        when "Ai"          then mark_as_grammar("A-#{convert_to_hiragana('i')}")                # i-adjective
        when "Aistem"      then mark_as_grammar("A-<del>#{convert_to_hiragana('i')}</del>")     # i-adjective stem
        when "Aku"         then mark_as_grammar("A-#{convert_to_hiragana('ku')}")               # i-adjective + ku
        when "Akute"       then mark_as_grammar("A-#{convert_to_hiragana('kute')}")             # i-adjective + kute
        when "Ana"         then mark_as_grammar("A-#{convert_to_hiragana('na')}")               # na-adjective
        when "Anastem"     then mark_as_grammar("A-<del>#{convert_to_hiragana('na')}</del>")    # na-adjective stem
        when "MIDDOT"      then "#{jp_unicode(0x30fb)}"                                         # katakana mid-dot
        when "SHIME"       then "#{jp_unicode(0x3006)}"                                         # "shime"
        when "JTILDE"      then "#{jp_unicode(0x301c)}"                                         # ~ (Japanese)
        when "JDOTS3"      then "#{jp_unicode(0x2026)}"                                         # ...
        when "JDOTS6"      then "#{jp_unicode(0x2026)}#{jp_unicode(0x2026)}"                    # ... (twice)
        when "KA"          then "#{jp_unicode(0x30f5)}"                                         # small ka
        when "KE"          then "#{jp_unicode(0x30f6)}"                                         # small ke
        when "KOME"        then "#{jp_unicode(0x203b)}"                                         # "rice symbol"
        when "JSTAR"       then "#{jp_unicode(0xff0a)}"                                         # 5 point line-star
        when "TICK"        then "#{jp_unicode(0x2713)}"                                         # tick symbol (check mark)
        when "QNTF"        then "<em>quantifier</em>"                                           # 
        when "QW"          then "<em>interrogative</em>"                                        # QW = question word = interrogative
        when "CTR"         then "<em>counter</em>"                                              # 
        when "ADV"         then "<em>adverb</em>"                                               # 
        when "PRT"         then "<em>particle</em>"                                             # 
        when "RELC"        then "<em>relative-clause</em>"                                      #
        when "HIMITSU"     then "<!-- DO_NOT_RELEASE -->"                                       # marker indicating source not to be released
        when "VERPEND"     then "<!-- UNVERIFIED -->"                                           # marker indicating something that has not been verified by a native speaker or book
        else
          debug_out("code: [#{code}]")
          "&lt;UNKNOWN @code [#{code}]&gt;"
        end
end

# Process a command of the form @ABC{{}}, i.e. one with no parameter
def process_empty_code(stack, code)
  return [ DoneText.new(process_empty_code_helper(code)) ]
end

# Process a command of the form @N123{{}}, @S123{{}}, @V123{{}}
def process_NSV(stack, code)
  contents = []
  stack.each() {
    |x|
    if x.processed?()
      contents << x
    else
      contents << DoneText.new(x.text())
    end
  }
  brackets = collapse_result(contents).text()
  string = code[0..0]
  sub = code[1..-1] # lose first character
  sub = convert_to_hiragana('te') if code == "V6" # TODO - just for comparison
  sub = convert_to_hiragana('ta') if code == "V7" # TODO - just for comparison
  string << "<sub>#{sub}</sub>" unless sub.nil?() || sub.empty?()
  string << "(#{brackets})" unless brackets.nil?() || brackets.empty?()
  string = mark_as_grammar(string) unless code =~ /^V\d$/ # TODO - just for comparison
  return [ DoneText.new(string) ] # TODO - mark_as_grammar here
end

# Adds emphasis to highlight a grammar point.
# Currently simply surrounds the parameter with <strong> and </strong>.
# The parameter is left alone and could be subject to further processing.
def process_emphasis(stack, code)
  result = []
  result << DoneText.new("<strong>")
  stack.each() {
    |x|
    result << x
  }
  result << DoneText.new("</strong>")
  return result
  
end

# Normal JHTML processing should discard @GRMIDX{{...}}
def process_grammar_index(stack, code)
  return []
end

# Handles @DIVSTART{{}}.
# Sets up the set of DIVs through which @DIV{{}} will cycle
def process_background_start(stack, unused)
  state = State.instance()
  names = []
  stack.each() {
    |x|
    names << x.text().split(/\s*,\s* /)
  }
  names = names.flatten()
  names = ["LightGrey", "MistyRose"] if names.empty?()
  state.divs_start(names.flatten())
  return []
end

# Handles @DIV{{}}
# Closes a previous <DIV> (if one exists) and opens a new one.
def process_background_insert(stack, unused)
  state = State.instance()

  text = ""
  # If a DIV is in progress, close it off
  text << insert_div_close() if state.divs_active?()

  # Start a new DIV
  name = "style-" + state.divs_next()
  text << "<DIV class=\"#{name}\"><p><br/></p>\n"
  return [ DoneText.new(text) ]
end

def process_background_end(stack, unused)
  state = State.instance()

  # If a DIV is in progress, close it off
  text = ""
  text << insert_div_close() if state.divs_active?()

  # Forget the existing DIVs
  state.divs_end()

  return [ DoneText.new(text) ]
end

def insert_div_close()
  return "\n<p><br/></p></DIV>\n"
end

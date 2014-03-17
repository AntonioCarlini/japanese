#!/usr/bin/ruby -w

$LOAD_PATH << File.dirname(__FILE__)

require 'DebugSupport.rb'
require 'HiraganaSupport.rb'
require 'KanjiSupport.rb'
require 'KatakanaSupport.rb'
require 'RefsSupport.rb'

OPENING_BRACKETS = Regexp.escape("{{")
CLOSING_BRACKETS = Regexp.escape("}}")

OPENING_REGEXP = "@\\w{1,15}#{OPENING_BRACKETS}"
CLOSING_REGEXP = "#{CLOSING_BRACKETS}"

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
    text += "..." if @text.size() > 30
    return "Text:        #{text}"
  end
end

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
    text += "..." if @text.size() > 30
    return "DoneText:    #{text}"
  end
end

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
  "Vmasu" => :process_empty_code,
  "Vmasustem" => :process_empty_code,
  "Vte" => :process_empty_code,
  "Vteiru" => :process_empty_code,
  "Vta" => :process_empty_code,
  "Vtara" => :process_empty_code,
  "Vba" => :process_empty_code,
  "Vyou" => :process_empty_code,
  "Vreru" => :process_empty_code,
  "Vrareru" => :process_empty_code,
  "Vsaseru" => :process_empty_code,
  "Vsasete" => :process_empty_code,
  "Vsaserareru" => :process_empty_code,
  "Ai" => :process_empty_code,
  "Aistem" => :process_empty_code,
  "Ana" => :process_empty_code,
  "Anastem" => :process_empty_code,

}

def process_at_commands(text)

  # REF is special and must be processed before anything else.
  # Recursive REFs make no sense so do not cater for them.
  begin
    text.gsub!(/@REF\{\{([^\}]+)\}\}/m) {
      |what|
      ref = $1
      debug_out("inserting for REF:[#{ref}]")
      transform_ref(ref)
    }
  end
  
  stack = []
  answer = ""

  to_handle = text

  if to_handle !~ /#{OPENING_REGEXP}/ixm
    debug_out("No command found")    
    answer += to_handle
    to_handle = nil
  end

  while !to_handle.nil?() && !to_handle.empty?()
    debug_out("Starting with to_handle.size = #{to_handle.size()}")    
    m = /(#{OPENING_REGEXP}|#{CLOSING_REGEXP})/ixm.match(to_handle)
    if !m.nil?()
      text = m.pre_match()
      current = m[0]
      to_handle = m.post_match().dup()
      debug_out("Found something to process")    
      
      if stack.empty?()
        answer += text
      else
        debug_out("Stacking text [#{text}]")    
        stack << Text.new(text)
      end

      if current =~ /#{CLOSING_REGEXP}/
        debug_out("Processing last command [#{current}]")
        # Build the mini stack
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
        raise("No object on the stack") if object.nil?()
        op = object.operation()
        raise("Object has no operation") if op.nil?()
        debug_out("Invoking [#{op}]")
        result = send(op, mini_stack, object.code())
        if stack.empty?()
          answer += puts_result(result)
        else
          debug_out("Stacking processed text")    
          stack << collapse_result(result)
        end

      else
        debug_out("Stacking command [#{current}]")
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
      answer += to_handle
      break
    end
    debug_out("Loop end: to_handle.size=#{to_handle.size()}")
  end

  unless stack.empty?()
    debug_out("Finished with non-empty stack")
    dump_stack(stack)
    raise("Non-empty stack")
  end

  return answer
end

# Given some text, substitute @REF{{}} statements as required. 
def transform_ref(text)
  res = ""
  ref = convert_ref(text)
  if ref.nil?()
    res = "&lt;UNKNOWN REF [#{ident}]&gt;"
  else
    alt = ref.alternate()
    res = "<span title=\"#{alt}\"> "unless alt.nil?() || alt.empty?()
    res += ref.text()
    res += "</span>" unless alt.nil?() || alt.empty?()
  end
  return res
end

def dump_stack(orig_stack)
  stack = orig_stack.dup()
  while !stack.empty?()
    item = stack.pop()
    debug("#{item.display()}")
  end
end

def mark_as_grammar(text)
  span_open = '<span class="grammar">'
  return "#{span_open}#{text}</span>"
end

def puts_result(stack)
  result = ""
  stack.each() {
    |x|
    raise("Trying to output OP") if x.op?()
    result += x.text()
  }
  return result
end

def collapse_result(stack)
  result = ""
  stack.each() {
    |x|
    raise("Found OP in result") if x.op?()
    result += x.text()
  }
  return DoneText.new(result)
end

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
  return result
end

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
  return result
end

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
  return result
end

def process_marker(stack, unused)
  return [ DoneText.new("[[MARKER:#{stack.last().text()}]]") ]
end

def process_catchall(stack, code)
  raise("code: #{code}")
  result = []
  stack.each() {
    |x|
    if x.processed?()
      result << x
    else
      result << DoneText.new(convert_to_katakana(x.text()))
    end
  }
  return result
end

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
        when "Vmasu"       then mark_as_grammar("V#{convert_to_hiragana('masu')}")              # masu form
        when "Vmasustem"   then mark_as_grammar("V<del>#{convert_to_hiragana('masu')}</del>")   # masu stem
        when "Vte"         then mark_as_grammar("V#{convert_to_hiragana('te')}")                # te-form
        when "Vta"         then mark_as_grammar("V#{convert_to_hiragana('ta')}")                # past
        when "Vtara"       then mark_as_grammar("V#{convert_to_hiragana('tara')}")              # ta-conditional
        when "Vteiru"      then mark_as_grammar("V#{convert_to_hiragana('teiru')}")             # te iru form
        when "Vba"         then mark_as_grammar("V#{convert_to_hiragana('ba')}")                # ba (conditional)
        when "Vyou"        then mark_as_grammar("V#{convert_to_hiragana('you')}")               # volitional
        when "Vreru"       then mark_as_grammar("V#{convert_to_hiragana('reru')}")              # potential
        when "Vrareru"     then mark_as_grammar("V#{convert_to_hiragana('rareru')}")            # passive
        when "Vsaseru"     then mark_as_grammar("V#{convert_to_hiragana('saseru')}")            # causative
        when "Vsasete"     then mark_as_grammar("V#{convert_to_hiragana('sasete')}")            # causative-te-form
        when "Vsaserareru" then mark_as_grammar("V#{convert_to_hiragana('saserareru')}")        # causative-passive
        when "Ai"          then mark_as_grammar("A-#{convert_to_hiragana('i')}")                # i-adjective
        when "Aistem"      then mark_as_grammar("A-<del>#{convert_to_hiragana('i')}</del>")     # i-adjective stem
        when "Ana"         then mark_as_grammar("A-#{convert_to_hiragana('na')}")               # na-adjective
        when "Anastem"     then mark_as_grammar("A-<del>#{convert_to_hiragana('na')}</del>")    # na-adjective stem
        else
          debug_out("Line: #{line_num}: Unknown {{}} code: [#{$1}]")
          "&lt;UNKNOWN @code [#{style}]&gt;"
        end
end

def process_empty_code(stack, code)
  return [ DoneText.new(process_empty_code_helper(code)) ]
end

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
  string += "<sub>#{sub}</sub>" unless sub.nil?() || sub.empty?()
  string += "(#{brackets})" unless brackets.nil?() || brackets.empty?()
  string = mark_as_grammar(string) unless code =~ /^V\d$/ # TODO - just for comparison
  return [ DoneText.new(string) ] # TODO - mark_as_grammar here
end


#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

$LOAD_PATH << File.dirname(__FILE__)

require 'AtCommandSupport.rb'
#require 'DataRefs.rb'
#require 'HiraganaSupport.rb'
#require 'KanjiSupport.rb'
#require 'KatakanaSupport.rb'
#require 'RefsSupport.rb'

# Process a verb data file and produce a suitable HTML table on output.

class Verb

  attr_reader :example
  attr_reader :kana
  attr_reader :key
  attr_reader :pair
  attr_reader :type
  attr_reader :verb
  attr_reader :vocab

  def initialize(key, verb, vocab, type, pair, example)
    @key = key
    @verb = verb
    @kana = process_at_commands("@HI{{#{verb}}}")
    @vocab = process_at_commands(vocab)
    @pair = pair
    @example = example
    case type
    when /t/ix
      @type = type
      @transitive = true
      @intransitive = false
    when /i/ix
      @type = type
      @transitive = false
      @intransitive = true
    else raise("Bad Verb initialisation: type = [#{type}]")
    end
  end

  def intransitive?()
    @intransitive
  end

  def transitive?()
    @transitive
  end

end

#+
# Usage: build-verb-tables.rb verbs.data
#-
def processing()

  file = ARGV.shift()
  if file.nil?()
    $stderr.puts("Usage: #{$0} verb-data-file")
    exit(1)
  end

  verbs = {}                                      # Hash to hold all verbs

  # Read the file
  file_text = IO.read(file)

  file_text.each_line() {
    |line|
    line = line.chomp().strip()                   # Lose EOL and excess whitespace
    next if line.nil?() || line.empty?()          # Skip empty lines
    debug_out("line=[#{line}]")
    to_handle = line
    key = nil      # unique verb identifier ... default value for verb if verb not specified
    verb = nil     # verb name (implicitly hiragana)
    type = nil     # T/I
    vocab = nil    # kanji
    pair = nil     # pair verb
    example = nil  # example sentence
    while !to_handle.nil?() && !to_handle.empty?()
      # Options are of the form word=string or word="string"
      # Check for the word="string" form first as that also matches word=form (without quotes)
      if to_handle =~ /^ \s* (\w+) \s* = \s*"([^"]+)"\s*(.*)/ix
        option = $1
        value = $2
        to_handle = $3
        debug_out("option=[#{option}] => [#{value}]")
      elsif to_handle =~ /^ \s* (\w+) \s* = \s*([^\s]+)\s*(.*)/ix
        option = $1
        value = $2
        to_handle = $3
        debug_out("option=[#{option}] => [#{value}]")
      else
        raise("UNKNOWN: [#{to_handle}")
      end
      raise("No option: [#{to_handle}]") if option.nil?() || option.empty?()
      raise("No option value: [#{option}]") if value.nil?() # || value.empty?()
      case option
      when "key"     then key = value
      when "verb"    then verb = value
      when "vocab"   then vocab = value
      when "type"    then type = value
      when "pair"    then pair = value
      when "example" then example = value
      end
    end

    verb = key if verb.nil?()

    # Options have been gathered ... build a Verb object
    raise("Failed to find key in [#{line}]") if key.nil?() || key.empty?()
    raise("Failed to find verb in [#{line}]") if verb.nil?() || verb.empty?()
    raise("Failed to find verb type in [#{line}]") if type.nil?() || type.empty?()
    raise("Failed to find verb spelling in [#{line}]") if vocab.nil?() || vocab.empty?()
    verbs[verb] = Verb.new(key, verb, vocab, type, pair, example)
  }

  # All verbs have been gathered.
  # Build alphabetical list based on verb spelling in kana.
  # Each entry is the transitive verb followed by the intransitive verb (if the latter is present).
  # If there is no transitive verb, then order according to intransitive verb + intransitive verb.
  # This way build a set of entries.
  # Check that for each pair they point to each other.
  table = {}              # Hash of index text => [transitive, intransitive]
  verbs.keys.each().each() {
    |k|
    v = verbs[k]
    t = i = nil
    if v.transitive?()
      t = v
      i = verbs[v.pair()] unless v.pair().nil?()
      raise("verb [#{v.verb}] has unmatched pair [#{i.pair()}]") unless i.nil?() || (i.pair() == v.verb())
    elsif v.intransitive?()
      i = v
      t = verbs[v.pair()] unless v.pair().nil?()
      raise("verb [#{v.verb}] has unmatched pair [#{t.pair()}]") unless t.nil?() || (t.pair() == v.verb())
    else
      raise("Unknown verb type: [#{v.verb}]")
    end
    if t.nil?()
      text = i.kana()
    else
      text = t.kana()
      text += i.kana() unless i.nil?()
    end
    table[text] = [t, i]
  }

  # Table has been built. Display it.

  # Page header
  puts('<!DOCTYPE html>')
  puts('<html>')
  puts('<head>')
  puts('<title>Dictionary of Intermediate Japanese Grammar</title>')
  puts('<link rel="stylesheet" type="text/css" href="japanese.css"/>')
  puts('<meta http-equiv="Content-Type" content="text/html; charset=utf-8">')
  puts('</head>')
  puts('<body>')
  puts('<h1>Dictionary of Intermediate Japanese Grammar</h1>')
  puts('<table BORDER="1">')
  puts('<tr><th>Transitive</th><th>Intransitive</th></tr>')
  # Table body
  table.keys().sort().each() {
    |k|
    t,i = table[k]
    row = "<tr><td>"
    row += "<span title=\"#{t.kana()}\">#{t.vocab}</span>" unless t.nil?()
    row += "</td><td>"
    row += "<span title=\"#{i.kana()}\">#{i.vocab}</span>" unless i.nil?()
    row += "</td></tr>"
    puts(row)
  }

  # Page footer
  puts('</table>')
  puts('</body>')
  puts('</html>')

end

# Wrap everything in a begin/end to facilitate error handling
begin
  processing()
end

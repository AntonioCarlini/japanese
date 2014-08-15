#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

$LOAD_PATH << File.dirname(__FILE__)

require 'AtCommandSupport.rb'
require 'DebugSupport.rb'

require 'strscan'

def handle_cli()
  if ARGV.empty?()
    $stderr.puts("Usage: #{File.basename($0)} text-to-translate\n")
    exit
  end

  return ARGV.shift()
end

class GrammarEntry

  attr_reader :anchor
  attr_reader :grammar
  attr_reader :index
  attr_reader :target

  def initialize(index, grammar, target)
    @index = index
    @grammar = grammar
    @target = target
    @anchor = ""
  end

  def set_anchor(text)
    @anchor = text
  end
end

DQ = '"'

TABLE_COLUMNS = 6               # This is the # of columns of data. There is an additional column for the indicator.
IND_COLUMN_WIDTH = 5            # Width of "indicator" column as a percentage
COLUMN_WIDTH = 15               # Entry column width as a percentage

SHORTCUT_TABLE_COLUMNS = 50     # Number of columns in shortcut table

TABLE_ORDER = [
  "a",    "i",    "u",    "e",    "o",
  "ka",   "ki",   "ku",   "ke",   "ko",
  "sa",   "shi",  "su",   "se",   "so",
  "ta",   "chi",  "xtsu", "tsu",  "te",   "to",
  "na",   "ni",   "nu",   "ne",   "no",
  "ha",   "hi",   "fu",   "he",   "ho",
  "ma",   "mi",   "mu",   "me",   "mo",
  "ya",           "yu",           "yo",
  "ra",   "ri",   "ru",   "re",   "ro",
  "wa",                   "wo",
  "nn"
]

# Display a row of information.
# current - an array of table elements to display.
# columns - the number of table columns (including the index column)
def display_current_row(current, columns)
  # Display nothing if there is nothing to display
  return if current.empty?()

  trailing_filler = columns - current.size()
  print('<tr>')
  current.each() {
    |entry|
    print('<td>' + entry + '</td>')
  }
  print('<td COLSPAN="' + trailing_filler.to_s() + '"> &nbsp; </td>') if trailing_filler > 0
  puts('</tr>')
end

# Display as many table rows as necessary. The first column in the first row
# will include the key text. The first column for all other rows will be blank.
#
# key     - key text for the first column of the first row
# entries - the text for the remaining columns and rows
# columns - the number of table columns (including the index column)
def display_all_for_key(key, entries, columns)

  return if entries.empty?()

  # Start with 3 blank rows
  blank = '<tr><td COLSPAN="' + columns.to_s() + '"> &nbsp; </td> </tr>'
  1.upto(3) { puts(blank) }

  # The tag for the first column differs depending on whether it is Japanese or English
  tag = entries.first().index().sub(/\s*<em>\s*/, "")
  if tag =~ /^&#x([[:xdigit:]]+);/
    tag = "hi-" + $1.upcase()
  elsif tag =~ /^([a-zA-Z\d])/
    tag = "en-" + $1.upcase()
  elsif tag =~ %r{\s*<span \s+ class="grammar">\s*}ix
    tag = "grammar"
  else
    tag = "special"
  end

  # The first column of the first row should include the key
  current_row = [ '<a name="' + tag + '">' + key + '</a>' ]

  entries.each() {
    |entry|

    add_tooltip = (entry.index =~ /&#x[[:xdigit:]]+;/)
    line  = '<a href="' + entry.target() + '">'
    line += '<span title="' + entry.index() + '">' if add_tooltip
    line += entry.grammar() + '</a>'
    line += '</span>' if add_tooltip
    line += '<br />'
    current_row << line
    if current_row.size() >= columns
      display_current_row(current_row, columns)
      current_row = [ '&nbsp;' ]
    end
  }

  display_current_row(current_row, columns) unless current_row.empty?()
end

def processing()

  entries = []

  ARGV.each() {
    |file|
    # Read the file and process each line.
    # The line format is:
    # filename: element1="..." [element2="..."]
    file_text = IO.read(file)
    file_text.each_line() {
      |line|
      line.chomp!()
      target = ""
      contents = ""
      if line =~ / ^ \s* ([^:]+) \s* : \s* (.*) $/ix
        target = $1
        contents = $2
        debug_out("Saw file [#{target}] with contents [#{contents}] in [#{line}]")
      else
        raise("Bad line: [#{line}}")
      end
      # Now process each element
      index = ""
      grammar = ""
      anchor = ""
      contents.scan(/\s* (\w+) \s* = \s* #{DQ}([^#{DQ}]+)#{DQ} \s* /ix) {
        |element, value|
        debug_out("  Found [#{element}] with value [#{value}]")
        case element
        when "index"      then index = process_at_commands(value)
        when "grammar"    then grammar = process_at_commands(value)
        when "anchor"     then anchor = process_at_value(value)
        else raise("Unkown element [#{element}] in [#{contents}]")
        end
      }
      entry = GrammarEntry.new(index, grammar, target)
      entry.set_anchor(anchor) unless anchor.empty?()
      entries << entry
    }
  }

  # Sort the entries according to the index.
  entries.sort!() { |a, b| a.index() <=> b.index() }

  # Build a table of hiragana mora in the expected order.
  ordered_hiragana = []
  TABLE_ORDER.each() { |mora| ordered_hiragana << convert_to_hiragana(mora) }

  
  japanese_index = []              # Japanese indexes used
  english_index = []               # English indexes used

  # A hash to store pages sorted by initial mora or initial uppercase lettera
  indexes = Hash.new() { |hash,key| hash[key] = [] }
  # An array to store pages that start with a grammatical item (e.g. Vte{{}})
  grammar_index = []
  # An array to store pages that don't make it any other hash
  other_index = []

  entries.each() {
    |entry|
    match_text = entry.index().sub(/\s*<em>\s*/, "")

    if match_text =~ /^&#x([[:xdigit:]]+);/
      # Store under the entry for a Japanese mora
      marker = $1
      first_mora = '&#x' + marker + ';'
      0.upto(3) {
        |idx|
        break if ordered_hiragana.include?(first_mora)
        first_mora = '&#x' + ("%x" % (marker.to_i(16) - idx)) + ';'
      }
      indexes[first_mora] << entry
      japanese_index << first_mora.upcase()
    elsif match_text =~ /^([a-zA-Z\d])/
      # Store under the entry for an English letter or number
      indexes[$1.upcase()] << entry
      english_index << $1.upcase()
    elsif match_text =~ %r{\s*<span \s+ class="grammar">\s*}ix
      # Grammatical terms
      grammar_index << entry
    else
      # Anything else
      other_index << entry
    end
  }

  puts('<!DOCTYPE html>')
  puts('<html>')
  puts('<head>')
  puts('<title>Grammar Index</title>')
  puts('<link rel="stylesheet" type="text/css" href="japanese.css"/>')
  puts('<meta http-equiv="Content-Type" content="text/html; charset=utf-8">')
  puts('</head>')
  puts('<body>')
  puts()
  puts('<h1>Grammar Index</h1>')

  # Begin the index table
  ji = []
  japanese_index.uniq().sort().each() {
    |code|
    # In &#x1234; lose the first 3 and the last characters
    ji << '<a href="#hi-' + code[3...-1] + '">' + code + '</a>'
  }

  ei = []
  english_index.uniq().sort().each() {
    |code|
    ei << '<a href="#en-' + code + '">' + code + '</a>'
  }

  puts('<table>')
  while !ji.nil?() && !ji.empty?()
    display_current_row(ji[0..(SHORTCUT_TABLE_COLUMNS - 1)], SHORTCUT_TABLE_COLUMNS)
    ji = ji[SHORTCUT_TABLE_COLUMNS..-1]
  end
  while !ei.nil?() && !ei.empty?()
    display_current_row(ei[0..(SHORTCUT_TABLE_COLUMNS - 1)], SHORTCUT_TABLE_COLUMNS)
    ei = ei[SHORTCUT_TABLE_COLUMNS..-1]
  end
  puts('<tr><td COLSPAN="20"><a href="#grammar">Grammar Entries</a></td></tr>')
  puts('<tr><td COLSPAN="20"><a href="#special">Other Entries</a></td></tr>')
  puts('</table>')

  puts('<table>')
  print('<tr><th WIDTH="' + IND_COLUMN_WIDTH.to_s() + '%">&nbsp</th>')
  1.upto(TABLE_COLUMNS) { print('<th WIDTH="' + COLUMN_WIDTH.to_s() + '%">&nbsp;</th>') }
  puts('</tr>')

  # Write out a suitable index page.
  indexes.keys().sort().each() { |key| display_all_for_key(key, indexes[key], TABLE_COLUMNS + 1) }
  display_all_for_key('&nbsp', grammar_index, TABLE_COLUMNS + 1)
  display_all_for_key('&nbsp', other_index, TABLE_COLUMNS + 1)

  puts('<table>')
  puts()
  puts('<br/><br/>')
  puts('Back to the <a href="index.html"> main index</a>.')
  puts()
  puts('</body>')
  puts('</html>')

end

# Wrap everything in a begin/end to facilitate error handling
begin
  processing()
end

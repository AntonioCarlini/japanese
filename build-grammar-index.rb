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

TABLE_COLUMNS = 6        # There is an additional column for the indicator
IND_COLUMN_WIDTH = 5     # Width of "indicator" column as a percentage
COLUMN_WIDTH = 15        # Entry column width as a percentage

TABLE_ORDER = [
  "a",    "i",    "u",    "e",    "o",
  "ka",   "ki",   "ku",   "ke",   "ko",
  "sa",   "shi",  "su",   "se",   "so",
  "ta",   "chi",  "tsu",  "te",   "to",
  "na",   "ni",   "nu",   "ne",   "no",
  "ha",   "hi",   "fu",   "he",   "ho",
  "ma",   "mi",   "mu",   "me",   "mo",
  "ya",           "yu",           "yo",
  "ra",   "ri",   "ru",   "re",   "ro",
  "wa",                   "wo",
  "nn"
]

def display_current_row(current)
  # Diusplay nothing if there is nothing to display
  return if current.empty?()

  print('<tr><td>&nbsp;</td>')
  current.each() {
    |entry|
    print('<td>' + entry + '</td>')
  }
  puts('</tr>')
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
  TABLE_ORDER.each() {
    |mora|
    ordered_hiragana << convert_to_hiragana(mora)
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

  puts('<table>') #  WIDTH="' + TABLE_WIDTH.to_s() + '%">')
  print('<tr><th WIDTH="' + IND_COLUMN_WIDTH.to_s() + '%">&nbsp</th>')
  1.upto(TABLE_COLUMNS) { print('<th WIDTH="' + COLUMN_WIDTH.to_s() + '%">&nbsp;</th>') }
  puts('</tr>')

  last_heading = nil
  # Write out a suitable index page.
  current_row = []
  entries.each() {
    |entry|
    # If this entry is to be ordered according to the rules of Japanese, find the first mora
    first_mora = nil
    if entry.index() =~ /^&#x([[:xdigit:]]+);/
      add_tooltip = true
      marker = $1
      first_mora = '&#x' + marker + ';'
      # If the new first mora isn't in the table of basic characters, do not switch to this first_mora
      first_mora = last_heading unless ordered_hiragana.include?(first_mora)
    else
      add_tooltip = false
    end

    unless first_mora.nil?()
      if last_heading.nil?() || first_mora != last_heading
        display_current_row(current_row)
        current_row = []
        blank = '<tr><td COLSPAN="' + (TABLE_COLUMNS + 1).to_s() + '"> &nbsp; </td> </tr>'
        1.upto(3) { puts(blank) } unless last_heading.nil?()
        puts('<tr> <td> <a name="' + marker + '">' + first_mora + '</a></td>' +
             '<td colspan="' + TABLE_COLUMNS.to_s() + '"> &nbsp; </td> </tr>')
        last_heading = first_mora
      end
    end

    add_tooltip = (entry.index =~ /&#x[[:xdigit:]]+;/)
    line  = '<a href="' + entry.target() + '">'
    line += '<span title="' + entry.index() + '">' if add_tooltip
    line += entry.grammar() + '</a>'
    line += '</span>' if add_tooltip
    line += '<br />'
    current_row << line
    if current_row.size() >= TABLE_COLUMNS
      display_current_row(current_row)
      current_row = []
    end
  }

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

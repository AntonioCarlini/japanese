#!/usr/bin/ruby -w
#encoding: UTF-8

$LOAD_PATH << File.dirname(__FILE__)

require 'Kanji.rb'

#+
# Provide support for reading data about a collection of kanji from a data file.
#-

# The file format is a number of fields separated by ":" characters:
# The fields (in order) are:
# - Heisig index
# - unicode (0xNNNN)
# - grade in Japanese school when this kanji is learned
# - a sequence of unique keywords separated by spaces (each keyword uniquely identfies this kanji)
# - a sequence of romanised onyomi separated by spaces
# - a sequence of romanised kunyomi separated by spaces
# - a sequence of romanised nanori separated by spaces
# - a sequence of english meanings, each enclosed in {}
#
class DataKanji

  attr_reader :kanji

  def initialize()
    @kanji = []
  end

  def <<(kanji)
    @kanji << kanji
  end

  def generate_unique_readings()
    # Try to select a unique reading => kanji mapping for each kanji
    # start by building a hash of reading => array of kanji
    readings = Hash.new() { |hash, key| hash[key] = [] }

    # List each kanji against all possible readings
    @kanji.each() {
      |k|
      (k.onyomi() + k.kunyomi()).each() {
        |r|
        readings[r] << k
      }
    }

    # Now find all unique readings and add each of these to its kanji
    readings.keys().sort().each() {
      |r|
      readings[r].first().add_reading(r) if readings[r].size() == 1
    }
  end

  def write_file(filename)
    op = File.new(filename, "w")
    @kanji.each() {
      |k|
      str = ""
      str << "%5d : " % k.heisig()
      str << " 0x%4.4x :" % k.unicode()
      str << " #{k.idents().join(' ')} : "
      str << " #{k.onyomi().join(' ')} : "
      str << " #{k.kunyomi().join(' ')} : "
      str << " #{k.nanori().join(' ')} : "
      str << " #{k.english()} : "
      str << " #{k.grade()} : "
      str << " #{k.jlpt()}"
      op.puts(str)
    }
    op.close()
  end

  def DataKanji.create_from_file(filename, options = {})
    
    kanji_data = DataKanji.new()

    kanji_limit = 0
    options.each() {
      |key, value|
      case key
      when :kanji_limit then    kanji_limit = value
      end
    }

    line_num = 0
    kanji_read = 0
    IO.read(filename).each_line() {
      |line|
      line.chomp!()
      line_num += 1

      # Bail out if kanji limit reached (useful for testing).
      next if kanji_limit > 0 && kanji_read >= kanji_limit

      # Skip commented out lines
      next if line =~ /^ \s+ #/

      fields = line.split(':')
      heisig = fields.shift().to_i()
      unicode = fields.shift().to_i(16)

      keywords = fields.shift().split(' ') # split keywords on space boundaries

      onyomi = fields.shift().split(' ')   # split onyomi on space boundaries
      kunyomi = fields.shift().split(' ')  # split kunyomi on space boundaries
      nanori = fields.shift().split(' ')   # split nanori on space boundaries
      meanings = fields.shift().split(/\s*\}\s*\{\s*/)
      meanings.first().sub!(/^\s*\{/, "") # Eliminate initial { on first meaning
      meanings.last().sub!(/\}\s*$/, "")  # Eliminate final } on last meaning
      
      grade = fields.shift().to_i()
      jlpt = fields.shift().to_i()

      # Keep the kanji in an array, ordered as they come from the data file
      k = Kanji.new(heisig, unicode, onyomi, kunyomi, nanori, meanings, grade, jlpt)
      keywords.each() { |word| k.add_reading(word) }
      kanji_data << k

      kanji_read += 1
    }

    return kanji_data
  end
end

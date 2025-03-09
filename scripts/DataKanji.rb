#!/usr/bin/ruby -w
#encoding: UTF-8

$LOAD_PATH << File.dirname(__FILE__)

require 'Kanji.rb'

MIN_EXPECTED_FIELDS = 8
MAX_EXPECTED_FIELDS = 9

#+
# Provide support for reading data about a collection of kanji from a file.
#
#
# The file format is a number of fields separated by ":" characters:
# The fields (in order) are:
# - Heisig index
# - unicode (0xNNNN)
# - a sequence of unique keywords separated by spaces (each keyword uniquely identfies this kanji)
# - a sequence of romanised onyomi separated by spaces
# - a sequence of romanised kunyomi separated by spaces
# - a sequence of romanised nanori separated by spaces
# - a sequence of english meanings, each enclosed in {}
# - grade in Japanese school when this kanji is learned
# - JLPG grade (old style, 1-4)

# I don't know what the range of Heisig frame numbers is on koohii.com.
# 3030 is a valid frame, 3031 is not. The next frame # I've found that works
# is 19970, but that's well beyond the Heisig range.
# So I've picked a conservative upper limit. Anything above this is taken
# to be a Unicode number.
MAX_HEISIG_FRAME_NUM = 4000

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
    fatal_seen = false

    kanji_limit = 0
    options.each() {
      |key, value|
      case key
      when :kanji_limit then    kanji_limit = value
      end
    }

    line_num = 0
    kanji_read = 0     # Number of kanji read so far
    last_heisig_frame_read = 0
    IO.read(filename).each_line() {
      |line|
      line_num += 1
      line.chomp!().strip!()
      next if line.empty?()

      # Bail out if kanji limit reached (useful for testing).
      next if kanji_limit > 0 && kanji_read >= kanji_limit

      # Skip commented out lines
      next if line =~ /^ \s+ #/

      # handle the parsing in a block so that 'rescue' can catch any parsing failures
      begin
        fields = line.split(':')
        if (fields.count() < MIN_EXPECTED_FIELDS) || (fields.count() > MAX_EXPECTED_FIELDS)
          $stderr.puts("FATAL wrong number of fields (saw #{fields.count()} expected #{MIn_EXPECTED_FIELDS}-#{MAX_EXPECTED_FIELDS} for line ##{line_num} [#{line}] in #{filename}]")
          fatal_seen = true
        end
        heisig = fields.shift().to_i()       # Heisig frame number (or Unicode value ?)
        unicode = fields.shift().to_i(16)    # Kanji Unicode value, in hex

        keywords = fields.shift().split(' ') # split keywords on space boundaries

        onyomi = fields.shift().split(' ')   # split onyomi on space boundaries
        kunyomi = fields.shift().split(' ')  # split kunyomi on space boundaries
        nanori = fields.shift().split(' ')   # split nanori on space boundaries
        meanings = fields.shift().split(/\s*\}\s*\{\s*/)
        meanings.first().sub!(/^\s*\{/, "") # Eliminate initial { on first meaning
        meanings.last().sub!(/\}\s*$/, "")  # Eliminate final } on last meaning
      
        grade = fields.shift().to_i()
        jlpt = fields.shift().to_i()

      rescue => e
        $stderr.puts("Error: #{e.class} - #{e.message}")
        $stderr.puts e.backtrace().first()
        $stderr.puts("FATAL error seen for line ##{line_num} [#{line}] in #{filename}]")
        fatal_seen = true
        next
      end
      
      # Quick sanity checks.
        
      # Beyond the Heisig frame number (i.e. anything beyond MAX_HEISIG_FRAME_NUM)
      # heisig and unicode must match.
      if heisig > MAX_HEISIG_FRAME_NUM
        raise("Heisig frame #{heisig} does not match Unicode #{unicode} on line #{line_num}") if heisig != unicode
      end

      # The heisig frame numbers should be monotonically increasing.
      # This isn't strictly necessary, but it helps keep the source file organised.
      # It also means there is no need to check for duplicate frame numbers as they cannot happen.
      raise("Heisig frame #{heisig} is not greater than previous frame #{last_heisig_frame_read}") if heisig <= last_heisig_frame_read
      last_heisig_frame_read = heisig
        
      # Keep the kanji in an array, ordered as they come from the data file
      k = Kanji.new(heisig, unicode, onyomi, kunyomi, nanori, meanings, grade, jlpt)
      keywords.each() { |word| k.add_reading(word) }
      kanji_data << k

      kanji_read += 1
    }

    raise "DataKanji: Processing failed with above errors" if fatal_seen

    return kanji_data
  end
end

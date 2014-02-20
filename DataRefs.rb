#!/usr/bin/ruby -w
#encoding: UTF-8

$LOAD_PATH << File.dirname(__FILE__)

#+
# Provide support for reading a set of references from a data file.
#-

# The file format is a number of fields separated by ":" characters:
# The fields (in order) are:
# - Reference ident
# - Reference text (may contain kanji, kana etc.)
# - Optional alternate text to display when hovering
#

class Reference

  attr_reader :alternate
  attr_reader :ident
  attr_reader :text

  def initialize(id, text, alternate)
    @ident = id                         # name by which the Reference is identified
    @text = text                        # text which is used to replace the reference
    @alternate = alternate              # "hover-over" alternate text
  end
  
end

class DataRefs

  attr_reader :refs

  def initialize()
    @refs = {}
  end

  def write_file(filename)
    op = File.new(filename, "w")
    @refs.each() {
      |r|
      str = ""
      str << " #{r.ident()} : "
      str << " #{r.text} : "
      str << " #{k.alternate()}"
      op.puts(str)
    }
    op.close()
  end

  def DataRefs.create_from_file(filename, options = {})
    
    refs_data = DataRefs.new()

    refs_limit = 0
    options.each() {
      |key, value|
      case key
      when :refs_limit then    refs_limit = value
      end
    }

    line_num = 0
    refs_read = 0
    IO.read(filename).each_line() {
      |line|
      line.chomp!()
      line_num += 1

      next if refs_limit > 0 && refs_read >= refs_limit

      # Skip commented out lines
      next if line =~ /^ \s+ #/

      fields = line.split('|')

      next if fields.nil?()

      ident = fields.shift().strip()
      text = fields.shift().strip()
      alternate = fields.shift()
      alternate.strip!() unless alternate.nil?()

      # Keep the reference in a hash
      refs_data.refs()[ident] = Reference.new(ident, text, alternate)

      refs_read += 1
    }

    return refs_data
  end
end

#!/usr/bin/ruby -w
#encoding: UTF-8

$LOAD_PATH << File.dirname(__FILE__)

#+
# A class that represents a single kanji.
#-

# Each kanji is represented by one Kanji object
class Kanji

  attr_reader :english
  attr_reader :heisig
  attr_reader :idents
  attr_reader :jlpt
  attr_reader :jouyou
  attr_reader :kunyomi
  attr_reader :nanori
  attr_reader :onyomi
  attr_reader :unicode

  def initialize(heisig, unicode, onyomi, kunyomi, nanori, english, jouyou, jlpt)
    @heisig = heisig
    @unicode = unicode
    @onyomi = onyomi
    @kunyomi = kunyomi
    @nanori = nanori
    @english = english
    @jouyou = jouyou
    @jlpt = jlpt
    @idents = []
  end

  def grade()
    @jouyou
  end

  def add_reading(reading)
    # Stop if the reading does not show up in onyomi or kunyomi
    unless @onyomi.include?(reading) || @kunyomi.include?(reading)
      $stderr.puts("ONYOMI:  [#{@onyomi.join(' ')}]")
      $stderr.puts("KUNYOMI: [#{@kunyomi.join(' ')}]")
      raise("Claimed reading [#{reading}] for [#{@heisig}] [#{@unicode}] is wrong")
    end

    @idents << reading
  end
end

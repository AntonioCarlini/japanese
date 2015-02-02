#!/usr/bin/ruby -w
#encoding: UTF-8

$LOAD_PATH << File.dirname(__FILE__)

#+
# A class that represents a single radical.
#-

# Each radical is represented by one Radical object
class Radical

  attr_reader :english
  attr_reader :reading
  attr_reader :unicode

  def initialize(english, reading, unicode)
    @unicode = unicode
    @reading = reading
    @english = english
  end

end

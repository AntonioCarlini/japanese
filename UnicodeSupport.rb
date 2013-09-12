#!/usr/bin/ruby -w

$LOAD_PATH << File.dirname(__FILE__)

require 'DebugSupport.rb'

def jp_unicode(x)
  begin
    return "&#x#{x.to_s(16)};"
  rescue
    debug_out("Messed up for [#{x}] class #{x.class}")
    raise
  end
end

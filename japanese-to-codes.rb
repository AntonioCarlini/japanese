#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

$LOAD_PATH << File.dirname(__FILE__)

require 'AtCommandSupport.rb'

def handle_cli()
  if ARGV.empty?()
    puts("Usage: #{File.basename($0)} text-to-translate\n")
    exit
  end

  file = ARGV.shift()
  if ARGV.empty?()
    output = file.sub(/\.jhtml$/, ".html")
  else
    output = ARGV.shift()
  end

  raise("Input file unsuitable") if output == file

  return file
end

def processing()

  file = handle_cli()

  # Read the file and process @include statements
  file_text = IO.read(file)
  include_seen = false
  begin
    include_seen = false
    file_text.gsub!(/@include\{\{\"([^\}]+)\"\}\}/m) {
      |what|
      include_seen = true
      filename = $1
      result = IO.read(filename)
      debug_out("inserting for:[#{result}]")
      result
    }
  end while include_seen
  
  # Special case V5{{text}} for now to match the original operation
  begin
    file_text.gsub!(/@V5\{\{([^\}]+)\}\}/m) {
      |what|
      text = $1
      string = "V<sub>5</sub>"
      string += "(#{text})" unless text.nil?() || text.empty?()
      string
    }
  end
  
  puts(process_at_commands(file_text))

end

# Wrap everything in a begin/end to facilitate error handling
begin
  processing()
end

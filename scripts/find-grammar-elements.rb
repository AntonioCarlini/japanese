#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

$LOAD_PATH << File.dirname(__FILE__)

require 'DebugSupport.rb'

require 'getoptlong'
require 'strscan'

def handle_cli()
  if ARGV.empty?()
    $stderr.puts("Usage: #{File.basename($0)} text-to-translate\n")
    exit
  end

  include_dir = ""

  args = GetoptLong.new(
                        [ "--include",   "-i", GetoptLong::REQUIRED_ARGUMENT ],
                        )

  begin
    args.each() {
      |option, arg|
      case option
      when "--include"       then include_dir = arg.dup()
      end
    }

  rescue GetoptLong::AmbigousOption => ambiguous_option
    $stderr << ambiguous_option << $endl
    exit(1)
  rescue GetoptLong::InvalidOption => invalid_option
    $stderr << invalid_option << $endl
    syntax
    exit(1)
  rescue GetoptLong::MissingArgument => missing_argument
    $stderr << missing_argument << $endl
    syntax
    exit(1)
  end

  file = ARGV.shift()

  return file, include_dir
end

def processing()

  file, include_dir = handle_cli()

  include_dir = include_dir + "/" unless (include_dir.empty?() || include_dir[-1,1] == "/")

  # Read the file and process @include statements
  file_text = IO.read(file)
  include_seen = false
  begin
    include_seen = false
    file_text.gsub!(/@include\{\{\"([^\}]+)\"\}\}/m) {
      |what|
      include_seen = true
      filename = include_dir + $1
      result = IO.read(filename)
      debug_out("inserting for:[#{result}]")
      result
    }
  end while include_seen
  
  # Build the scanner
  s = StringScanner.new(file_text)

  while true do                                   # Loop (until no further matches
    # Start by matching @GRMIDX{{
    found = s.scan_until(/@GRMIDX\{\{/ixm)
    break if found.nil?()                         # Stop if no more @GRMIDX{{...}}
    close_reqd = 1                                # Need one set of closing brackets
    start = s.pos()

    # Now find the matching closing }}
    while close_reqd > 0 do
      # Now repeatedly go to the next "}}" and count the number of {{ present.
      current = s.scan_until(/\{\{|\}\}/ixm)    # Find next item
      exit if current.nil?()                    # Missing at least one set of closing brackets
      if s.matched() == "{{"
        close_reqd += 1                         # Found opening brackets
      else
        close_reqd -= 1                         # Found closing brackets
      end
      # If close_reqd == 0 then done ...
      if close_reqd == 0
        stop = s.pos() - 3                      # The current pointer is one beyond "}}", so back 3 to capture just the contents of @GRMIDX{{...}}
        debug_out("Looking at #{start} => #{stop} in total of #{file_text.length()}")
        contents = file_text[start .. stop]     # Capture the required string
        debug_out("Found        @GRMIDX{{#{contents}}}")
        puts("#{file.sub(/.jhtml$/,'.html')}: #{contents}")
      end
    end
  end
end

# Wrap everything in a begin/end to facilitate error handling
begin
  processing()
end

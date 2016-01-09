#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

$LOAD_PATH << File.dirname(__FILE__)

require 'AtCommandSupport.rb'

require 'getoptlong'

def handle_cli()
  if ARGV.empty?()
    puts("Usage: #{File.basename($0)} text-to-translate\n")
    exit
  end

  data_dir = ""
  include_dir = ""

  args = GetoptLong.new(
                        [ "--data",      "-d", GetoptLong::REQUIRED_ARGUMENT ],
                        [ "--include",   "-i", GetoptLong::REQUIRED_ARGUMENT ],
                        )

  begin
    args.each() {
      |option, arg|
      case option
      when "--data"          then data_dir = arg.dup()
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
  if ARGV.empty?()
    output = file.sub(/\.jhtml$/, ".html")
  else
    output = ARGV.shift()
  end

  raise("Input file unsuitable") if output == file

  return file, data_dir, include_dir
end

def processing()

  file, data_dir, include_dir = handle_cli()

  data_dir = data_dir + "/" unless (data_dir.empty?() || data_dir[-1,1] == "/")
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
  
  puts(process_at_commands(file_text, data_dir, file))

end

# Wrap everything in a begin/end to facilitate error handling
begin
  processing()
end

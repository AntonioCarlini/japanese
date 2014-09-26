#!/usr/bin/ruby -w

$LOAD_PATH << File.dirname(__FILE__)

require 'DataRefs.rb'
require 'DebugSupport.rb'

$ref_data = nil
def convert_ref(ref, data_dir)
  if $ref_data.nil?()
    data_filename = data_dir.nil?() ? "" : data_dir.dup()
    data_filename += "/" unless (data_filename.empty?() || data_filename[-1,1] == "/")
    data_filename += "references.data"
    ref_data_file = "#{data_filename}"
    $ref_data = DataRefs.create_from_file(ref_data_file)
  end

  r = nil

  if ref =~ /JPOD101-(\w+)-S(\d)-(\d\d\d)/
    level = $1
    season = $2
    number = $3.to_i()
    full_level_name = nil
    case level
    when "BG" then full_level_name = "Beginner"
    when "UB" then full_level_name = "Upper Beginner"
    when "LI" then full_level_name = "Lower Intermediate"
    when "IN" then full_level_name = "Intermediate"
    when "UI" then full_level_name = "Upper Intermediate"
    end
    r = Reference.new(ref, "JapanesePOD101.com, #{full_level_name} Season #{season}, Lesson ##{number}", "")
  else
    r = $ref_data.refs()[ref]
    if r.nil?()
      debug_out("@REF{{#{ref}}} => nil")
    else
      debug_out("@REF{{#{ref}}} => [#{r.text()} / #{r.alternate()}]")
    end
  end
  return r
end

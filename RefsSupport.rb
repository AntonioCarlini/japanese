#!/usr/bin/ruby -w

$LOAD_PATH << File.dirname(__FILE__)

require 'DebugSupport.rb'

$ref_data = nil
def convert_ref(ref)
  if $ref_data.nil?()
    ref_data_file = "references.data" # Hard code this for now
    $ref_data = DataRefs.create_from_file(ref_data_file)
  end
  r = $ref_data.refs()[ref]
  if r.nil?()
    debug_out("@REF{{#{ref}}} => nil")
  else
    debug_out("@REF{{#{ref}}} => [#{r.text()} / #{r.alternate()}]")
  end
  return r
end

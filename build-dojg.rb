#!/usr/bin/ruby -w

# Turn some grammar text into the correct encoding.
# If the text does not start with an alphabetic, then leave it alone (mostly)
# Otherwise
#  - encode as @HI{{..}}
#  - ensure that "~" has one space before and after
#
# Once that is done change [N] into a superscript.
def code_grammar(text)
  result = text
  if text =~ /^[A-Za-z0-9]/
    result = ""
    chunks = text.split(/([^a-zA-Z])/)    # break where not hiragana
    chunks.each() {
      |part|
      part.strip!()
      next if part.empty?()
      if part =~ /^[a-zA-Z]/
        result +="@HI{{" + part + "}}"
      else
        part = " ~ " if part =~ /^\s*~\s*$/  # make sure ~ has spaces around it
        result += part
      end
    }
  end
  result.sub!(/\[(\d+)\]/, '<sup>\1</sup>')
  return result.squeeze(" ").strip()
end

entries = IO.read(ARGV.shift()).lines().map(&:chomp)

puts('<!DOCTYPE html>')
puts('<html>')
puts('<head>')
puts('<title>Dictionary of Advanced Japanese Grammar</title>')
puts('<link rel="stylesheet" type="text/css" href="japanese.css" />')
puts('<meta http-equiv="Content-Type" content="text/html; charset=utf-8">')
puts('</head>')
puts('<style>')
puts('table.progress td.left {')
puts(' text-align: left')
puts('}')
puts('</style>')
puts('<body>')
puts('<h1>Dictionary of Basic Japanese Grammar</h1>')


puts('<table class="progress">')
puts('<tr>')
puts('  <th colspan="2"> &nbsp; </th> <th colspan="2"> Studied </th> <th> SRS </th> <th> Grammar </th>')
puts('</tr>')
puts('<tr>')
puts('  <th> Heading </th>')
puts('  <th> Location </th>')
puts('  <th> Vocabulary </th> <th> Grammar </th> <th> Sentences </th> <th> Notes Made </th>')
puts('</tr>')

entries.each() {
  |data|
  page_text, grammar = data.split(' ', 2)
  page = page_text.to_i()
  raise("Bad page #{page} from [#{page_text}] in [#{data}]") if page <= 0 || page > 1000

  grammar = code_grammar(grammar)
  puts('<tr>')
  puts('  <td class="left"> <a href="grammar-.html"></a>' + ("%-68s" % grammar) + '</td>')
  puts('  <td class=""> DOBJG, p.' + ("%-3d" % page) + (' ' * 88) + '</td>')
  puts('  <td class=""> </td> <td class=""> </td> <td class=""> </td> <td class=""> </td>')
  puts('</tr>')
}

puts('</table>')
puts()
puts('</body>')
puts('</html>')

#!/usr/bin/env ruby
=begin legal crap
    rubylexer - a ruby lexer written in ruby
    Copyright (C) 2004,2005,2008  Caleb Clausen

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
=end

module DeleteWarns
FN='[^\n]+'
DATETIME='\d+-\d\d?-\d\d? \d\d:\d\d:\d\d\.\d+ -?\d+'
INDENTLINE='(?: [^\n]*\n)'

WARNERRREX='(?:Reading a token: )?-:(\d+): (warning|(?:syntax )?error)(?:: ([^\n]+))?'

RE=%r"(?#--- #{FN}	#{DATETIME}
\+\+\+ #{FN}	#{DATETIME}
)^@@ -\d+,\d+ \+\d+,\d+ @@
#{INDENTLINE}+\
-(?:Reading a token: )?-:(\d+): (warning|error): ([^\n]+)\n\
\+(?:Reading a token: )?-:(\d+): \2: \3
#{INDENTLINE}+"mo

RE2=%r"^@@ -\d+,\d+ \+\d+,\d+ @@
#{INDENTLINE}*\
\+#{WARNERRREX}\n\
#{INDENTLINE}*"mo

RE3=%r"^@@ -\d+,\d+ \+\d+,\d+ @@
#{INDENTLINE}+\
-(?:Reading a token: )?-:(\d+): (warning|error): ([^\n]+)\n\
#{INDENTLINE}+"mo

def DeleteWarns.deletewarns(input)
input.each('\n--- ') {|match|
   yield match.gsub(RE,"\\2 moved from \\1 to \\4: \\3\n")  \
              .gsub(RE2,"Created \\2(s) in new file, line \\1: \\3\n") \
              .gsub(RE3,"Removed \\2(s) from old file (?!), line \\1: \\3\n")
}
end
end

if __FILE__==$0
  DeleteWarns.deletewarns($stdin){|s| $stdout.print s}
end

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

$Debug=true
require 'rubylexer'
require 'getoptlong'

#def puts(x) end

#a Token#inspect that omits the object id
class RubyLexer
class Token
  def strify
    [self.class.name[/[^:]+$/],": ",instance_variables.sort.collect{|v| 
      [v,"=",instance_variable_get(v).inspect," "]
    }].join
  end
end
end

name=macros=silent=file=nil
options={}
#allow -e
opts=GetoptLong.new(
  ["--eval", "-e", GetoptLong::REQUIRED_ARGUMENT],
  ["--silent", "-s", GetoptLong::NO_ARGUMENT],
  ["--macro", "-m", GetoptLong::NO_ARGUMENT],
  ["--ruby19", "--1.9", "-9", GetoptLong::NO_ARGUMENT]
)
opts.each{|opt,arg|
  case opt
  when '--eval'
    file=arg
    name='-e'
  when '--silent'
    silent=true
  when '--macro'
    macros=true
  when '--ruby19'
    options[:rubyversion]=1.9
  end
}
     
#determine input file and its name if not already known
file||=if name=ARGV.first
    File.open(name)
  else 
    name='-'
    $stdin.read
  end

args=name, file
args.push 1,0,options unless options.empty?
lexer=RubyLexer.new(*args) 
lexer.enable_macros! if macros
if silent
  until RubyLexer::EoiToken===(tok=lexer.get1token)
  end
else
  until RubyLexer::EoiToken===(tok=lexer.get1token)
    puts tok.strify
  end
end
puts tok.strify #print eoi token

#!/usr/bin/ruby
=begin legal
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
#$DEBUG=$VERBOSE=true
$Debug=true
require "getoptlong"
require "test/code/tokentest"
require "test/code/deletewarns"


module RubyLexerVsRuby;end
class<<RubyLexerVsRuby
ENABLEMD5=false
def nop_ruby(cmd,input,output,stringdata)
#   system %[echo "BEGIN{exit};">#{output}]
   File.open(output,'w'){|f|
     if stringdata 
       stringdata=stringdata.dup
       first=stringdata.slice! /\A.*\n?/
       second=stringdata.slice! /\A.*\n?/
     else
       input=IO.popen %{#{cmd} "#{input}"}
       first=input.readline
       second=input.readline
       stringdata=input.read
     end
     if first[0,2]=="#!"
       if /\A\s*#.*coding/o===second
         f.write first
         f.write second
         f.write "BEGIN{exit};\n"
         f.write stringdata
       else
         f.write first
         f.write "BEGIN{exit};\n"
         f.write second
         f.write stringdata
       end
     else
       if /\A\s*#.*coding/o===first
         f.write first
         f.write "BEGIN{exit};\n"
         f.write second
         f.write stringdata
       else
         f.write "BEGIN{exit};\n"
         f.write first
         f.write second
         f.write stringdata
       end
     end
   }
end

def ruby_parsedump(input,output,ruby)
  #todo: use ruby's md5 lib
  #recursive ruby call here is unavoidable because -y flag has to be set

  #do nothing if input unchanged
  ENABLEMD5 and system "md5sum -c #{input}.md5 2>/dev/null" and return

  status=0
  IO.popen("#{ruby} -w -y < #{input} 2>&1"){ |pipe| 
    File.open(output,"w") { |outfd|
      pipe.each{ |line|
        outfd.print(line) \
          if /^Shifting|^#{DeleteWarns::WARNERRREX}/o===line
        #elsif /(warning|error)/i===line
        #  raise("a warning or error, appearently, not caught by rex above: "+line)
      }
      #pid,status=Process.waitpid2 pipe.pid #get err status of subprocess
    } 
  }
  status=$?
  ENABLEMD5 and status==0 and system "md5sum #{input} > #{input}.md5" #compute sum only if no errors
  return status>>8
end

def head(fname)
  File.open(fname){|fd| print(fd.read(512)+"\n") }
end


def progress ruby,input
  print "executing: #{ruby} -Ilib test/code/tokentest.rb --keepws #{input}\n"
  $stdout.flush
end

def rubylexervsruby(input,stringdata=nil,difflines=nil,bulk=nil,&ignore_it)
#cmdpath= `which #$0`
cmddir=Dir.getwd+"/test/code/"
Dir.mkdir 'test/results' unless File.directory? 'test/results'
base='test/results/'+File.basename(input)
_ttfile=base+'.tt'
mttfile=base+'.mtt'
p_ttfile=_ttfile+'.prs'
pmttfile=mttfile+'.prs'
p_ttdiff=p_ttfile+'.diff'
pmttdiff=pmttfile+'.diff'
nopfile=base+'.nop'
origfile=nopfile+'.prs'
ruby=ENV['RUBY'] || 'ruby'
expected_failures=Dir.getwd+"/test/code/"+File.basename(input)+".expected_failures"

#olddir=Dir.pwd
#Dir.chdir cmddir + '/../..'

nop_ruby "#{input[/\.gz$/]&&'z'}cat", input, nopfile, stringdata


ruby_parsedump nopfile, origfile, ruby
`#{ruby} -c #{nopfile} >/dev/null 2>/dev/null`; legal=$?.to_i
if legal.nonzero?
  puts "skipping #{input}; not legal"
  return true
end

progress ruby, input
begin
  tokentest nopfile, RubyLexer, RubyLexer::KeepWsTokenPrinter.new, nil, _ttfile
  tokentest nopfile, RubyLexer, RubyLexer::KeepWsTokenPrinter.new(' '), nil, mttfile
rescue Exception=>rl_oops
end

begin
  p_tt_fail=true unless 0==ruby_parsedump( _ttfile, p_ttfile, ruby )
  pmtt_fail=true unless 0==ruby_parsedump( mttfile, pmttfile, ruby )
rescue Exception=>ru_oops
end

warn "syntax error parsing #{pmttfile}" if pmtt_fail
warn "syntax error parsing #{p_ttfile}" if p_tt_fail

if rl_oops
  if ru_oops
    #good, ignore it
    return true
  else
    raise rl_oops
  end
elsif ru_oops
  warn "syntax error expected, was not seen in #{input}"
  return true
end


if File.exists?(p_ttfile)
  IO.popen("diff --unified=1 -b #{origfile} #{p_ttfile}"){ |pipe|
  File.open(p_ttdiff,"w") { |diff|
    DeleteWarns.deletewarns(pipe){|s| diff.print s}
  }
  }
#  File.unlink p_ttfile
end

if File.exists?(pmttfile)
  IO.popen("diff --unified=1 -b #{origfile} #{pmttfile}"){ |pipe|
  File.open(pmttdiff,"w") { |diff|
    DeleteWarns.deletewarns(pipe){|s| diff.print s}
  }
  }
#  File.unlink pmttfile
end

list=[]
#nonwarn4=/(^(?![^\n]*warning[^\n]*)[^\n]*\n){4,}/im
#4 or more non-warning lines:
nonwarn4=/^(?:(?![^\r\n]*warning)[^\n]+\n){4,}/mi
result=true
(system "ruby -c #{input} >/dev/null 2>&1" or expected="(expected) ") unless stringdata
for name in [p_ttdiff,pmttdiff] do
  i=File.read(name) rescue next
 # i.tr("\r","\n")
#  i.gsub!(/^\n/m, '')
  i.sub!(/\A([^\r\n]+(\r\n?|\n\r?)){2}/, '')  #remove 1st 2 lines
  i.scan nonwarn4 do |j|
    unless ignore_it && ignore_it[j]
      list.push( *j.split(/\r\n?|\n\r?/) ) #unless list.size>=10
    end
  end
  
  unless list.empty?
  list=list.join("\n") +"\n"
  unless (File.exists?(expected_failures) and File.read(expected_failures)==list)
    result=!!expected
    print "#{expected}error in: #{input}\n"
    (difflines ? difflines.push(*list) : print(list)) unless expected
  end
    list=[]
  end
end

#print( list.join("\n") +"\n")
#Dir.chdir olddir
File.unlink(*Dir[base+".{tt,mtt,nop}{,.prs}{,.diff}"]) if result and bulk

return result

=begin
case File.zero?(p_ttdiff).to_s +
     File.zero?(pmttdiff).to_s
  when 'falsefalse' then
    head p_ttdiff
    print "omitting #{pmttdiff}\n"
  when 'falsetrue'
    head p_ttdiff
  when 'truefalse'
    head pmttdiff
  when 'truetrue'
    #File.unlink origfile
    return true
  default
    raise "unexpected 2bool val"
end
return false
=end

rescue Interrupt; raise
rescue Exception
  File.exist? nopfile and
    system "ruby -c #{nopfile} >/dev/null 2>&1" or expected="(expected) " unless stringdata
  print "#{expected}error in: #{input}\n"
  File.unlink(*Dir[base+".{tt,mtt,nop}{,.prs}{,.diff}"]) if expected and bulk
  return true if expected
  raise
end
end

if __FILE__==$0
#allow -e
stringdata=input=nil
opts=GetoptLong.new(["--eval", "-e", GetoptLong::REQUIRED_ARGUMENT])
opts.each{|opt,arg|
  opt=='--eval' or raise :impossible
  stringdata=arg
  input='-e'
}

input||=ARGV[0]

unless input
  input="-"
  stringdata=$stdin.read
end
RubyLexerVsRuby.rubylexervsruby(input,stringdata) and exit 0

exit 1
end



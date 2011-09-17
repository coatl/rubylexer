#!/usr/bin/ruby
=begin legalia
    rubylexer - a ruby lexer written in ruby
    Copyright (C) 2004,2005,2008, 2011  Caleb Clausen

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
require "rubylexer"
require "getoptlong"
require "pp"

class RubyLexer
class Token
  def verify_offset(fd); false end
  
  def check_for_error; end
end

class LexerError<Exception; end

module ErrorToken
  def check_for_error; raise LexerError,@error end
end

class FileAndLineToken
  def verify_offset(fd); true  end
end
class ImplicitParamListStartToken
  def verify_offset(fd); true  end
end
class ImplicitParamListEndToken
  def verify_offset(fd); true  end
end

module SimpleVerify
  def verify_offset(fd)
    fd.read(@ident.length)==@ident
  end
end

class WToken;      include SimpleVerify; end
class IgnoreToken; include SimpleVerify; end
class MethNameToken; include SimpleVerify; end

class NewlineToken
  include SimpleVerify
  def verify_offset(fd)
    super or fd.eof?
  end
end

class SymbolToken
  def verify_offset(fd)
    la=fd.read(2)
    case la
      when '%s'
        quote=fd.read(1)
        ender=RubyLexer::PAIRS[quote] || quote
        body=@ident[2...-1]
      when /^:(['"])/
        #stay right here
        quote=ender=$1
        body=@ident[2...-1]
      when /^:/
        fd.pos-=1
        body=@ident[1..-1]
      else raise 'unrecognized symbol type'
    end
    
    bodyread=fd.read(body.length)

    #punt if its too hard
    if quote
      bs="\\"
      hardstuff= Regexp.new %/[#{bs}#{quote}#{bs}#{ender}\#\\\\]/
      return true if (body+bodyread).match(hardstuff)
    end

    if bodyread==body
      return fd.read(1)==ender if ender 
      return true 
    end
  end
end

class EoiToken
  include SimpleVerify
  def verify_offset(fd)
    result=super(fd)
    fd.eof?
    return result
  end
end

class NoWsToken
  def verify_offset(fd)
    orig=fd.pos
    fd.pos=orig-1
    result= (/^[^\s\v\t\n\r\f]{2}$/===fd.read(2))
    fd.pos=orig
    return result
  end
end

class HereBodyToken
  def verify_offset(fd)
    @ident.verify_subtoken_offsets(fd)
  end
end

class HerePlaceholderToken
  def verify_offset(fd)
    '<<'==fd.read(2) or return false
    @dash and ('-'==fd.read(1) or return false)
    case ch=fd.read(1)[0]
      when ?', ?`, ?"
        @quote==ch.chr and
        fd.read(@ender.size)==@ender and
        return fd.read(1)==@quote
      when ?a..?z, ?A..?Z, ?_, ?0..?9
        @quote=='"' or return false
        fd.pos-=1
        fd.read(@ender.size)==@ender or return false
      else
        return false
    end
  end
end

class StringToken
  FANCY_QUOTE_BEGINNINGS= {'`'=>'%x', '['=>'%w', '{'=>'%W',
                           '"'=>/('|%[^a-pr-z0-9])/i, '/'=>'%r'}
  def verify_offset(fd)
    fd.read(open.size)==open  or return false
#    str=fd.read(2)
#    @char==str[0,1] or FANCY_QUOTE_BEGINNINGS[@char]===str or return false
    verify_subtoken_offsets(fd)
  end

  def verify_subtoken_offsets(fd)
    #verify offsets of subtokens
    @elems.each{|elem|
      case elem
      when String
        #get string data to compare against,
        #translating dos newlines to unix.
        #(buffer mgt is a PITA)
        goal=elem.size
        saw=fd.read(goal)
        saw.gsub!("\r\n","\n")
        now_at=nil
        loop do
          now_at=saw.size
          saw.chomp!("\r") and fd.pos-=1 and now_at-=1
          break if now_at>=goal
          more=fd.read([goal-now_at,2].max)
          more.gsub!("\r\n","\n")
          saw<<more
        end
        #assert now_at<=goal+1 #not needed
        saw[goal..-1]='' unless goal==now_at
        saw==elem  or return false
      else elem.verify_offset(fd) or raise LexerError
      end
    }
    return true
  end
  
  def check_for_error
    1.step(@elems.size-1,2){|idx|
      @elems[idx].check_for_error
    }
    super
  end
end

class RubyCode
  def verify_offset(fd)
    thistok=nexttok=endpos=nil
    @ident.each_index{ |tok_i|
      thistok,nexttok=@ident[tok_i,2]
      endpos=nexttok ? nexttok.offset : thistok.offset+thistok.to_s.size
      check_offset(thistok,fd,endpos)
    }
    assert nexttok.nil?
    assert thistok.object_id==@ident.last.object_id
    assert(( WToken===thistok or EoiToken===thistok&&thistok.error ))
    fd.pos=endpos
  end
  
  def check_for_error
    @ident.each{|tok| tok.check_for_error }
  end
end


class NumberToken
  def verify_offset(fd)
    /^[0-9?+-]$/===fd.read(1)
  end
end


#class ZwToken
#  def to_s
#    $ShowImplicit ? explicit_form : super
#  end
#end
end

public


def check_offset(tok,file=nil,endpos=nil)
  #the errors detected here are now reduced to warnings....
  file||=@original_file
  String===file and file=file.to_sequence
  allow_ooo= @moretokens&&@moretokens[0]&&@moretokens[0].allow_ooo_offset unless endpos
  endpos||=((@moretokens.empty?)? input_position : @moretokens[0].offset)
  oldpos=file.pos

  assert Integer===tok.offset
  assert Integer===endpos
  if endpos<tok.offset and !allow_ooo
    $stderr.puts "expected #{endpos} to be >= #{tok.offset} token #{tok.to_s.gsub("\n","\n  ")}:#{tok.class}"
  end

  file.pos=tok.offset
  tok.verify_offset(file) or 
     $stderr.puts "couldn't check offset of token #{tok.class}: #{tok.to_s.gsub("\n","\n  ")} at #{tok.offset}"
  case tok
    when RubyLexer::StringToken,RubyLexer::NumberToken,
         RubyLexer::HereBodyToken,RubyLexer::SymbolToken,
         RubyLexer::HerePlaceholderToken,
         RubyLexer::FileAndLineToken #do nothing
    else 
      file.pos==endpos or allow_ooo or 
        $stderr.puts "positions don't line up, expected #{endpos}, got #{file.pos}, token: #{tok.to_s.gsub("\n","\n  ") }"
  end
  file.pos=oldpos
  return
end





def tokentest(name,lexertype,pprinter,input=File.open(name),output=$stdout)
  input ||= File.open(name)
  if output!=$stdout
    output=File.open(output,'w')
  end

  input=input.read if IO===input and not File===input

  fd=input
  #File.open(name) {|fd|
    lxr=lexertype.new(name,fd,1)

    begin
      tok=lxr.get1token
      lxr.check_offset(tok)
      tok.check_for_error
      pprinter.pprint(tok,output)
    end until RubyLexer::EoiToken===tok

    #hack for SimpleTokenPrinter....
    print "\n" if RubyLexer::NewlineToken===lxr.last_operative_token and
                  RubyLexer::SimpleTokenPrinter===pprinter

#    unless lxr.balanced_braces? 
#      raise "unbalanced braces at eof"
#    end
  #}
   output.close unless output==$stdout

end

#$ShowImplicit=false
if __FILE__==$0

  sep,line,showzw='',1,0
#  lexertype= RumaLexer if defined? RumaLexer
  lexertype=RubyLexer
  insertnils=fd=name=loop=nil
  pprinter=RubyLexer::SimpleTokenPrinter

  opts=GetoptLong.new \
    ["--eval","-e", GetoptLong::REQUIRED_ARGUMENT],
#    ["--ruby","-r", GetoptLong::NO_ARGUMENT],
    ["--keepws","-k", GetoptLong::NO_ARGUMENT],
    ["--maxws","-m", GetoptLong::NO_ARGUMENT],
    ["--implicit","-i", GetoptLong::NO_ARGUMENT],
    ["--implicit-all", GetoptLong::NO_ARGUMENT],
    ["--loop", GetoptLong::NO_ARGUMENT]

  saweval=nil
  opts.each do|opt,arg|
    case opt
    when '--eval'   then 
       tokentest('-e',lexertype,pprinter.new(sep,line,showzw),arg)
       saweval=arg
#    when '--ruby'   then lexertype=RubyLexer
    when '--keepws' then pprinter= RubyLexer::KeepWsTokenPrinter
    when '--maxws'  then pprinter= RubyLexer::KeepWsTokenPrinter;sep=' '
    when '--implicit' then showzw=1
    when '--implicit-all' then showzw=2
    when '--loop' then loop=true
    else raise :impossible
    end
  end

  pprinter =pprinter.new(sep,line,showzw)
  
  begin
    if ARGV.empty?     
      saweval ? 
        tokentest('-e',lexertype,pprinter,saweval) : 
        tokentest('-',lexertype,pprinter,$stdin) 
    else
      ARGV.each{|fn| tokentest(fn,lexertype,pprinter) } 
    end
#  ARGV.first[/[_.]rb$/i] and lexertype=RubyLexer  #filename with _rb are special hack
  end while loop

end

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



require "assert"


class RubyLexer

#-------------------------------
class SimpleTokenPrinter

   def initialize(*bogus)
      @tokens=@srclines=0
   end

   TOKENSPERLINE=8
   TOKENSMAGICMAP="\n"+' '*(TOKENSPERLINE-1)

   def pprint(tok,output=$stdout) output<<(sprint(tok)) end

   def sprint(tok)
      case tok
      when Newline then "#{@lastfal if ((@srclines+=1)%16==0)} #; "
      when FileAndLineToken then @lastfal=tok;''
      when IgnoreToken then ''  #skip comments&whitespace
      else tok.to_s + TOKENSMAGICMAP[ (@tokens+=1) % TOKENSPERLINE, 1 ]
      end
   end
end

   class EscNlToken; def ws_munge(tp)
      tp.lasttok=self
      return " \\\n"
   end end
   class FileAndLineToken; def ws_munge(tp)
      result=''
      
      #faugh, doesn't fix it
      #result= "\\\n"*(line-tp.lastfal.line) if StringToken===tp.lasttok 
      
      tp.lasttok=self
      tp.lastfal=self
      return result
   end end
   class Newline; def ws_munge(tp)
      tp.lasttok=self
      return"#{tp.lastfal_every_10_lines}\n"
   end end
   class IgnoreToken; def ws_munge(tp)
         #tp.latestline+= to_s.scan("\n").size
         tp.lasttok=self
         result=unless tp.inws
           tp.inws=true
           ' '
         else
           ''
         end
         #if ?= == @ident.to_s[0]
           result+="\\\n"*@ident.to_s.scan(/\r\n?|\n\r?/).size
         #end
         
         return result
   end end
   class HereBodyToken; def ws_munge(tp) #experimental
     nil
   end end
   class OutlinedHereBodyToken; def ws_munge(tp)
     nil
   end end
   class EncodingDeclToken; def ws_munge(tp)
     nil
   end end
   class ZwToken; def ws_munge(tp)
      case tp.showzw 
      when 2; explicit_form_all
      when 1; explicit_form
      when 0; nil
      else raise 'unknown showzw'
      end
   end end
   class Token; def ws_munge(tp)
      nil
   end end

#-------------------------------
class KeepWsTokenPrinter
   attr_accessor :lasttok, :lastfal, :inws #,:latestline
   attr :showzw
   ACCUMSIZE=50


   def initialize(sep='',line=1,showzw=0)
      @sep=sep
      @inws=false
      @lasttok=''
      #@latestline=line
      @lastprintline=0
      @accum=[]
      @showzw=showzw
   end

   def pprint(tok,output=$stdout)
      @accum<<aprint(tok).to_s
      if (@accum.size>ACCUMSIZE and NewlineToken===tok) or EoiToken===tok
         output<<(@accum.join)
         @accum=[]
      end
   end

   def aprint(tok)
      if StringToken===tok or 
          HereBodyToken===tok
#         (HerePlaceholderToken===tok and 
#          tok.bodyclass!=OutlinedHereBodyToken
#         )
            str_needs_escnls=(tok.line-@lastfal.line).nonzero?
      end if false
      result=tok.ws_munge(self) and return result


      #insert extra ws unless an ambiguous op immediately follows
      #id or num, in which case ws would change the meaning
      result=tok
      result=
      case tok
      when ZwToken,EoiToken,NoWsToken, HereBodyToken, NewlineToken,
           ImplicitParamListStartToken,ImplicitParamListEndToken;
        tok
      else
        @sep.dup<<tok.to_s
      end unless NoWsToken===lasttok
      
      if str_needs_escnls
        result=result.to_s
        result.gsub!(/(["`\/])$/){ "\\\n"*str_needs_escnls+$1 }
      end

      @lasttok=tok
      @inws=false

      return result
   end

   alias sprint aprint

   def lastfal_every_10_lines
      if(@lastprintline+=1) > 10
         @lastprintline=0
         %Q[ #@lastfal]
      end
   end


   #insert extra ws unless an ambiguous op immediately follows
   #id or num, in which case ws would change the meaning
   def ws_would_change_meaning?(tok,lasttok)   #yukk -- is it used?
      tok.kind_of?(String) and
      /^[%(]$/===tok and #is ambiguous operator?
          lasttok and
          (lasttok.kind_of?(Numeric) or
           (lasttok.kind_of?(String) and
            /^[$@a-zA-Z_]/===@lasttok)) #lasttok is id or num?
   end
end
end

#-------------------------------


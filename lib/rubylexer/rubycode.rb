=begin copyright
    rubylexer - a ruby lexer written in ruby
    Copyright (C) 2004,2005, 2011  Caleb Clausen

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



#require "token.rb"
#require "tokenprinter.rb"

class RubyLexer

class RubyCode < Token
   def initialize(tokens,filename,linenum)
      super(tokens)
      @filename=filename
      @linenum=linenum
   end

   attr :linenum

   def [](*args)
      exec? ident.huh
   end

   def to_s()
      result=[]
      keepwsprinter=KeepWsTokenPrinter.new('',@linenum)
      ident.each{|tok| result << keepwsprinter.sprint(tok) }
      return result.join
   end
end
end


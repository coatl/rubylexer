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

require "rubylexer/charset"
class RubyLexer
#------------------------------------
class CharHandler
  #-----------------------------------
  CHARSETSPECIALS=CharSet[?[ ,?] ,?\\ ,?-]
  def initialize(receiver,default,hash) 
    @default=default 
    @receiver=receiver
 #breakpoint
    @table=Array.new(0)
    @matcher='^[^'

    hash.each_pair {|pattern,action|
      case pattern
      when Range
        pattern.each { |c|
          c.kind_of? String and c=c[0] #cvt to integer  #still needed?
          self[c]=action
        }
      when String
        pattern.each_byte {|b| self[b]=action }
      when Fixnum
        self[pattern]=action
      else
        raise "invalid pattern class #{pattern.class}: #{pattern}"
      end
    }

    @matcher += ']$'
    @matcher=Regexp.new(@matcher)

    freeze
  end

  #-----------------------------------
  def []=(b,action)  #for use in initialize only
    assert b >= ?\x00
    assert b <= ?\xFF
    assert !frozen?

    @table[b]=action
    @matcher << ?\\ if CHARSETSPECIALS===b
    @matcher << b
  end
  private :[]=

  #-----------------------------------
  def go(b,*args)
    @receiver.send((@table[b] or @default), b.chr, *args)
  end

  #-----------------------------------
  def eat_file(file,blocksize,*args)
    begin
      chars=file.read(blocksize)
      md=@matcher.match(chars)
      mychar=md[0][0]
      #get file back in the right pos
      file.pos+=md.offset(0)[0] - chars.length
      @receiver.send(@default,md[0])
    end until go(mychar,*args)
  end
end
end



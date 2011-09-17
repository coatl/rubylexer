=begin
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

require "rubylexer/charset"
class RubyLexer
#------------------------------------
class CharHandler
  #-----------------------------------
  if ?A.is_a? String #ruby >= 1.9
    CHARSETSPECIALS=/[\[\]\\\-]/
  else
    CHARSETSPECIALS=CharSet[?[ ,?] ,?\\ ,?-]
  end
  def initialize(receiver,default,hash) 
    @default=default 
    @receiver=receiver
    if ?A.is_a? String #ruby >= 1.9
      @table={}
    else
      @table=Array.new(0)
    end
    @matcher='^[^'

    hash.each_pair {|pattern,action|
      case pattern
      when Range
        pattern.each { |c|
          self[c]=action
        }
      when String
        CharHandler.each_char(pattern) {|b| self[b]=action }
      when Fixnum
        self[pattern]=action
      else
        raise "invalid pattern class #{pattern.class}: #{pattern}"
      end
    }

    @matcher += ']$'
    @matcher=Regexp.new(@matcher,0,'n')

    freeze
  end

  #-----------------------------------
  if String===?a 
    def self.each_char(str,&block)
      str.each_char(&block)
    end
  else
    def self.each_char(str,&block)
      str.each_byte(&block)
    end
  end

  #-----------------------------------
  def []=(b,action)  #for use in initialize only
    assert b >= ?\x00
    assert b <= ?\x7F
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

end
end



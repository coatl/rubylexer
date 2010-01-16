=begin copyright
    rubylexer - a ruby lexer written in ruby
    Copyright (C) 2004,2005  Caleb Clausen

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

class RubyLexer
class CharSet
   def initialize(*charss)
      clear
      charss.each {|chars| add chars }
   end

   def CharSet.[](*charss)        CharSet.new(*charss)       end

   def clear
      @bitset=0
   end

   def add(chars)
      case chars
      when ::String
         chars.each_byte {|c| @bitset |= (1<<c) }
      when ::Fixnum then      @bitset |= (1<<chars)
      else chars.each    {|c| @bitset |= (1<<c) }
      end
   end

   def remove(chars)
      case chars
      when String
         chars.each_byte {|c| @bitset &= ~(1<<c) }
      when Fixnum then        @bitset &= ~(1<<chars)
      else chars.each    {|c| @bitset &= ~(1<<c) }
      end
      #this math works right with bignums... (i'm pretty sure)
   end

   if String==="a"[0]
     def ===(c) #c is String|Fixnum|nil
       c.nil? and return false
       c.kind_of? String and c=c.getbyte(0)
       return ( @bitset[c] != 0 )
     end
   else
     def ===(c) #c is String|Fixnum|nil
       c.nil? and return false
       c.kind_of? String and c=c[0]
       return ( @bitset[c] != 0 )
     end
   end

   #enumerate the chars in n AS INTEGERS
   def each_byte(&block)
      #should use ffs... not available in ruby
      (0..255).each { |n|
         @bitset[n].nonzero? and block[n]
      }
   end

   def each(&block)
      each_byte{|n| block[n.chr] }
   end

   def chars #turn bitset back into a string
      result=''
      each {|c| result << c }
      return result
   end
end
end


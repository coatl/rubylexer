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

class RubyLexer
class SymbolTable
   def initialize
      #note: below Stack means Array (used as a stack)
      @symbols={} #Hash of String to Stack of Object(user-defined)
      @locals_lists=[{}] #Stack of Hash of String to Boolean
   end

   def start_block
      assert @locals_lists.last
      @locals_lists.push({})
      assert @locals_lists.last
   end

   def end_block
      assert @locals_lists.last
      list=@locals_lists.pop
      list or raise "unbalanced end block"
      list.each_key {|sym|
         @symbols[sym].pop
         @symbols[sym].empty? and @symbols.delete sym
      }
      assert @locals_lists.last
   end

   def deep_copy
     result=SymbolTable.allocate
     new_symbols={}
     @symbols.each_pair{|str,stack|
       new_symbols[str.clone]=stack.map{|elem| elem.clone rescue elem }
     }
     new_locals_lists=[]
     @locals_lists.each{|hash|
       new_locals_lists.push({})
       hash.each_pair{|str,bool|
         new_locals_lists.last[str.dup]=bool
       }
     }
     new_locals_lists.push({}) if new_locals_lists.empty?
     result.instance_eval{
       @symbols=new_symbols
       @locals_lists=new_locals_lists
     }
     return result
   end

   def names
     @symbols.keys
   end

   def __locals_lists
     @locals_lists
   end

   def [](name)
      assert @locals_lists.last
      (stack=@symbols[name]) and stack.last
   end

   alias === []

   def []=(name, val)
      assert @locals_lists.last
      if @locals_lists.last and @locals_lists.last[name]
         #already defined in this block
         @symbols[name][-1]=val #overwrite current value
      else
         stack=(@symbols[name] ||= [])
         stack.push val
         @locals_lists.last[name]=true
      end
      assert @locals_lists.last
      return val
   end
end
end

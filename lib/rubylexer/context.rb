=begin legal crap
    rubylexer - a ruby lexer written in ruby
    Copyright (C) 2008  Caleb Clausen

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
module NestedContexts
  class NestedContext
    attr :starter
    attr :ender
    attr :linenum
    def initialize(starter,ender,linenum)
      @starter,@ender,@linenum=starter,ender,linenum
    end

    alias dflt_initialize initialize

    def matches?(tok)
      @ender==tok
    end
    
    def see lxr,msg; end
    def lhs=*x; end #do nothing
    def wantarrow; false end
  end

  #contexts which expect to see commas,
  #(other than assignment lhs, which has no context)
  class ListContext < NestedContext 
  end
  
  class ListImmedContext < ListContext
    def initialize(starter,linenum)
      assert '{['[starter]
      super(starter, starter.tr('{[','}]') ,linenum)
    end
    def wantarrow; true end
  end

  class ParenContext < NestedContext
    def initialize(linenum)
      super('(', ')' ,linenum)
    end
   
    attr_accessor :lhs
    def see(lxr,msg)
      @lhs=true if msg==:comma || msg==:splat
    end
  end

  class KnownNestedLhsParenContext < ParenContext
    def lhs; true end
    def lhs=x; end
    def see(lxr,msg) end
  end

  class BlockContext  < NestedContext
    def initialize(linenum)
      super('{','}',linenum)
    end
  end

  class BeginEndContext  < NestedContext
    def initialize(str,linenum)
      super('{','}',linenum)
    end
  end

#  class BlockParamListContext  < ListContext
#    def initialize(linenum)
#      super('|','|',linenum)
#    end
#  end

  class ParamListContext < ListContext
    def initialize(linenum)
      super('(', ')',linenum)
    end
    def lhs; false end
    def wantarrow; true end
  end
  
  class ImplicitLhsContext < NestedContext
    def initialize(linenum)
      @linenum=linenum
    end
    def lhs; true end
    def starter; nil end
    def ender; '=' end
  end
  
  class BlockParamListLhsContext < ImplicitLhsContext    
    def starter; '|' end
    def ender; '|' end
  end

  class ImplicitContext < ListContext
  end

  class ParamListContextNoParen < ImplicitContext
    def initialize(linenum)
      super(nil,nil,linenum)
    end
    def lhs; false end
    def wantarrow; true end
  end

  class KWParamListContextNoParen < ParamListContextNoParen
  end

  class WhenParamListContext < ImplicitContext
    def initialize(starter,linenum)
      super(starter,nil,linenum)
    end
  end

  class AssignmentContext < NestedContext
    def initialize(linenum)
      super("assignment context", "=",linenum)
    end
  end

  class AssignmentRhsContext < ImplicitContext
    def initialize(linenum)
      super(nil,nil,linenum)
    end
    def see lxr,msg
      case msg
      when :semi; lxr.parsestack.pop
      when :comma,:splat; @multi=true
      end
    end
    def multi_assign?
      @multi if defined? @multi 
    end
  end

  class WantsEndContext < NestedContext
    def initialize(starter,linenum)
      super(starter,'end',linenum)
      @state=nil
    end

    attr_accessor :state
    
    def see lxr,msg
      msg==:rescue and lxr.parsestack.push_rescue_sm 
    end
  end

  class ClassContext < WantsEndContext
    def see(lxr,msg)
      if msg==:semi and @state!=:semi
        lxr.localvars_stack.push SymbolTable.new 
        @state=:semi
      else
        super
      end
    end
  end

  class DefContext < WantsEndContext
    def initialize(linenum)
      super('def', linenum)
      @in_body=false
    end

    def see(lxr,msg)
      if msg==:semi and @state!=:semi
        @in_body=true
        @state=:semi
      else
        super
      end
    end

    attr :in_body
  end

  class StringContext < NestedContext #not used yet
    def initialize(starter,linenum)
      super(starter, starter[-1,1].tr!('{[(','}])'),linenum)
    end
  end

  class HereStringContext < StringContext #not used yet
    def initialize(ender,linenum)
      dflt_initialize("\n",ender,linenum)
    end
  end

  class TopLevelContext < NestedContext
    def initialize
      dflt_initialize('','',1)
    end
  end


  class RescueSMContext < ListContext
    #normal progression: rescue => arrow => then
    EVENTS=[:rescue,:arrow,:then,:semi,:colon]
    LEGAL_SUCCESSORS={
      nil=> [:rescue], 
      :rescue => [:arrow,:then,:semi,:colon], 
      :arrow => [:then,:semi,:colon],
      :then => []
    }
    #note on :semi and :colon events:
    #      (unescaped) newline, semicolon, and (unaccompanied) colon 
    #      also trigger the :then event. they are ignored if in :then 
    #      state already.
    attr :state
    
    def initialize linenum
      dflt_initialize("rescue","then",linenum)
      @state=nil
      @state=:rescue 
    end
    
    def see(lxr,msg)
      stack=lxr.parsestack
      case msg
      when :rescue: 
        WantsEndContext===stack.last or 
          BlockContext===stack.last or 
          ParenContext===stack.last or 
          raise 'syntax error: rescue not expected at this time'
      when :arrow: #local var defined in this state
      when :then,:semi,:colon:
        msg=:then
        self.equal? stack.pop or raise 'syntax error: then not expected at this time'
                  #pop self off owning context stack
      when :comma, :splat: return
      else super
      end
      LEGAL_SUCCESSORS[@state].include? msg or raise "rescue syntax error: #{msg} unexpected in #@state"
      @state=msg
    end
    
  end

  class ForSMContext < ImplicitLhsContext
    #normal progression: for => in 
    EVENTS=[:for,:in]
    LEGAL_SUCCESSORS={nil=> [:for], :for => [:in],:in => []}
    #note on :semi and :colon events: in :in state (and only then), 
    #      (unescaped) newline, semicolon, and (unaccompanied) colon 
    #      also trigger the :then event. otherwise, they are ignored.
    attr :state
    
    def initialize linenum
      dflt_initialize("for","in",linenum)
      @state=:for
    end
    
    def see(lxr,msg)
      stack=lxr.parsestack
      assert msg!=:for
      case msg
      when :for: WantsEndContext===stack.last or raise 'syntax error: for not expected at this time'
                 #local var defined in this state
                 #never actually used?
      when :in:  self.equal? stack.pop or raise 'syntax error: in not expected at this time'
                 stack.push ExpectDoOrNlContext.new("for",/(do|;|:|\n)/,@linenum) 
                 #pop self off owning context stack and push ExpectDoOrNlContext
      when :comma, :splat: return
      else super
      end
      LEGAL_SUCCESSORS[@state].include? msg or raise "for syntax error: #{msg} unexpected in #@state"
      @state=msg
    end    
  end

  class ExpectDoOrNlContext < NestedContext
  end

  class ExpectThenOrNlContext < NestedContext
    def initialize starter, linenum
      super starter, "then", linenum
    end
  end

  class TernaryContext < NestedContext
    def initialize(linenum)
      dflt_initialize('?',':',linenum)
    end
  end
end
end

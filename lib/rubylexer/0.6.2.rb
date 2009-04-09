require 'rubylexer/0.7.0'

#make ImplicitParamList Start and End tokens descend from IgnoreToken again
class RubyLexer
  remove_const :ImplicitParamListStartToken
  remove_const :ImplicitParamListEndToken

  class ImplicitParamListStartToken < IgnoreToken
#    include StillIgnoreToken
    def initialize(offset)
      super("(",offset)
    end
    def to_s; '' end
  end

  class ImplicitParamListEndToken < IgnoreToken
#    include StillIgnoreToken
    def initialize(offset)
      super(")",offset)
    end
    def to_s; '' end
  end
end

RubyLexer.constants.map{|k| 
  k.name[/[^:]+$/] if Token>=k or Context>=k
}.compact + %w[
  RuLexer CharHandler CharSet SymbolTable 
  SimpleTokenPrinter KeepWsTokenPrinter
].each{|name|
  Object.const_set name, RubyLexer.const_get name
}


class RubyLexer
  def merge_assignment_op_in_setter_callsites?
    true
  end
end

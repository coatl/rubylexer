#Copyright (c) 2011 Caleb Clausen
class RubyLexer
  class Rule
    def initialize(lead,matcher,*actions)
      fail unless String===lead or Fixnum===lead
      @lead,@matcher,@actions=lead,matcher,actions
    end
  end

  class Mode #set of Rules
    def initialize(rules)
      rules.map!{|r| Rule.new(*r) }
      @rules=rules
      fail if rules.size>255
      rules.each_with_index{|r,i| all_chars_of(r.lead).each{|char|
        @chartable[char]||=''
        @chartable[char]<<i
      }}
      #should order of rules in @chartable[x] be tweaked?
    end
  end

  lc_letters="a-z_"  #this is correct for ascii, other charsets will need different char classes here
  uc_letters="A-Z"   #this is always A-Z, for all charsets
  letters=lc_letters+uc_letters

  num=/(0(x[_0-9a-f]+|
          d[_0-9]+|
          b[_01]+|
          o?[_0-7]+)|
        [1-9][_0-9]*
        (\.[_0-9]+)?
        (e[+-]?[_0-9]+)?
      /ix
  #this might allow leading and trailing _ where ruby does not

  ws="\s\t\r\v\f"
  eqbegin= /=begin(#{ws}.*)?\n((?!=end[#{ws}\n]).*\n)*=end(#{ws}.*)?$/
  ews=/([#{ws}]+|\\$|\#.*$|\n#{eqbegin}?)*/
  ews_no_nl=/([#{ws}]+|\\\n(#{eqbegin}\n)?)+/

  var=/[#{letters}][#{letters}0-9]*/
  civar=/@@?#{var}/
  gs=/[^#{ws}\n\#\x0- -]|-[#{letters}0-9]?/
  gvar=/$(#{var}|#{gs})/

  method=/#{var}[?!]?/
  method_eq=/#{var}[?!=]?/

  loopers=/c|C-|m|M-/
  simple_esc=/\\([^cCmMx0-7]|x[0-9a-fA-F]{1,2}|[0-7]{1,3})/
  loop_esc= /(\\#{loopers}(
              [^\\](?!\\#{loopers})|
              #{simple_esc}(?!\\#{loopers})|
              (?=\\#{loopers})
             )+
            /mx
  esc=/#{simple_esc}|#{loop_esc}/

  definately_val=/
    [~!`@${(\['":]|
    [%^\-+/](?!=)|
    <<-?[`'"#{letters}]|
    [0-9#{letters}]
  /x

  CommonMode=Mode.new(
    [ws,/[#{ws}]+/,WhitespaceToken,:stay],
    [?\\,EscNlToken,:stay],
    [?#, /\#.*$/,CommentToken,:stay]
    #[],
  )

  ValueMode=CommonMode|Mode.new(
    [?$, gvar, VarNameToken],
    [?@, civar, VarNameToken],
    ["!~&*", /./, UnaryOpToken, ValueMode],
    [?%, /%[qw][^#{lc_letter.sub'_',''}A-Z0-9]/, StringStartToken, :push_context, string_mode(?'){|ss| ss[-1]}],
    [%['], /./, StringStartToken, :push_context, string_mode(?'){?'}],
    [%["`/], /./, StringStartToken, :push_context, string_mode(?"){|ss| ss[-1]}],
    #[?^,/./, UnaryOpToken, ValueMode],
    #["&*", /./, UnaryOpToken, ValueMode], #unary
    ["+-", /[+-]#{num}/, NumberToken], #numeric
    ["+-", /[+-]/, UnaryOpToken, ValueMode], #unary
    [?|, /./,KeywordToken, :block_params, :push_context, ValueMode], #goalpost
    [?:, /:(?=['"])/, UnaryColonToken, ValueMode], #symbol
    [?:, /:(#{gvar}|#{civar}|#{method_eq}|#{operator_method}|`|\[\]=?)/, SymbolToken], #symbol
    [?{, /./, OperatorToken, :push_context, ValueMode], #hash lit
    [?[, /./, OperatorToken, :push_context, ValueMode], #array lit
    [?<, /<<-?#{var}|'[^']*'|"[^"]*"|`[^`]*`/, :here_doc, HereDocHeadToken], #here doc
    [??, /\?([^\\#{ws}\n]|#{esc})/, CharToken], #char lit
    ["0-9", num, NumberToken],
    ["A-Z", method, :const_or_method], #use JustAfterMethodMode to figure out what to output/where to go
    [lc_letters, method, :lvar_or_method],#use JustAfterMethodMode to figure out what to output/where to go
    ["(",/./, KeywordToken, :push_context, ValueMode],

    #indicates empty construct or trailing comma or semicolon (or nl)
    [?}, /./, :pop_context, :pop_soft_scope?, :block_end?, huhToken, OpMode]
    ['])', /./, :pop_context, huhToken, OpMode]
    
    [?\\, "\\\n", :escnl, WhitespaceToken, ValueMode]
    [?\n, :escnl, WhitespaceToken, ValueMode]
    [".,", :error], 
    [:begin, :maybe_rescue_etc, :push_context,ValueMode]
    [:def, :hard_scope, :maybe_rescue_etc, :push_context, :nasty_custom_parser_here, ValueMode]
    [/if|unless/, :maybe_then, :maybe_else, :push_context,ValueMode]
    [/while|until/, :maybe_do, :push_context,ValueMode]
    [:for, :expect_in, :maybe_do, :push_context,ValueMode]
    [:class, :push_hard_scope, :maybe_rescue_etc, :maybe_lt, :push_context,ValueMode]
    [:module, :push_hard_scope, :maybe_rescue_etc, :maybe_include, :push_context,ValueMode]
    [:end, :pop_hard_scope?, :pop_context, OpMode]
    [/return|next|break/] #these are special in subtle ways I forget....
    [huh FUNCLIKE_KEYWORDS, huh]
    [huh VARLIKE_KEYWORDS, huh]
    [:BEGIN, huh]
    [:END, huh]
    [:case]
    [:when]
    [:defined?]
    
    
    {:others=>:error,
    :default=>OpMode}
  )

  OpMode=CommonMode|Mode.new(
    [";,", /./, OperatorToken]
    ["%/^", /.=?/, :could_be_assign, OperatorToken]
    ["&*+-", /(.)\1?=?/, :could_be_assign, OperatorToken],
    [?|, /\|\|?=?/, :could_be_assign, :could_be_end_goalpost, OperatorToken],
    [?<, /<<=?/, :could_be_assign, OperatorToken], 
    [?>, />>=?/, :could_be_assign, OperatorToken],
    [?<, /<=?>?/, OperatorToken], #also gets <>
    [?>, />=?/, OperatorToken],
    [?=, /=(~|>|=?=?)/, :could_be_assign, OperatorToken]
    ["0-9",huh,:error]
    [letters,huh,:error]
    [?:, /::(?=#{ews}[#{uc_letter}][#{letter}]*(?![?`~@${\(]|!([^=]|$)#{ews_no_nl}#{definately_val}))/, OperatorToken] 
    [?:, /::/, OperatorToken, MethodNameMode] 
    #constant if capitalized and not followed by (implicit or explicit) param list and not ending in ? or ! , else method
    [?:, /:/, OperatorToken]
    [?., /\.\.\.?/, OperatorToken]
    [?., /\.(?!\.)/, OperatorToken, MethodNameMode]
    [?{, /./, :push_context, :push_soft_scope, :block_start, :maybe_goalposts, huhToken]
    [?}, /./, :pop_context, :pop_soft_scope?, :block_end?, huhToken, OpMode]
    ['])', /./, :pop_context, huhToken, OpMode]
    [/and|or|if|unless|while|until|rescue/, OperatorToken]
    [:do, :must_be_after_rparen, :push_soft_scope, :maybe_goalposts, KeywordToken]
    [:do, :if_allowed, KeywordToken]
    [:end, :pop_hard_scope?, :pop_context, OpMode]
    {:others=>:error,
    :default=>ValueMode}
  )
  MethodNameMode=CommonMode|Mode.new(
    [letters, method, MethodNameToken],
    [?`,/./, huh, MethodNameToken],
    [huh, operator_method, MethodNameToken]
    [?[, /\[\]=?/, MethodNameToken]
    #[?(] #in ruby 1.9
    {:default=>JustAfterMethodMode}
  )

  JustAfterMethodMode=OpMode|Mode.new(
    [ws, /[#{ws}]+/, WhitespaceToken, AfterMethodMode],
    #[?\\] #hrm?
    [?(,huh,:push_context, ParamListStartToken, ValueMode]
    [?{,huh,:push_context, :push_soft_scope, :block_start, huhToken, ValueMode]
    [huh nil, /(?= [^#{ws}({] )/x, :no_token, OpMode]
  )
  AfterMethodMode=Mode.new(
    #these indicate implicit parens unless followed by ws
    [?/, /./, StringStartToken, :iparen, :push_context, string_mode(?"){?/}],
    ['+-*&',huh, :iparen, ValueMode]
    #[?^]
    [?%,huh,]
    [?`,huh,]

    [?:,huh,] #tricky... operator in ternary context, else always symbol

    #these indicate implicit parens always
    [?[, //, :iparen, ValueMode]
    [lc_letters, //, :iparen, OpMode]
    ["$@A-Z", //, :iparen, OpMode]
    ["0-9", //, :iparen, OpMode]
    [%[~!], //, :iparen, ValueMode]


    [?<, /(?=<<-?['"#{lc_letters}])/i, :iparen, OpMode]
    [?{, //, :iparens2, OpMode]
    [?=, //, :iparens2, OpMode]
    [?;, //, :iparens2, OpMode]

    [?(] #tricky, need to look ahead for commas

    [")]}",/./,:iparens2, OpMode]
    []
    {:default=>huh}
  )

  AfterNewline=Mode.new
  StringInteriorMode=Mode.new

end

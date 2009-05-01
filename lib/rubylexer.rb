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


require 'rubylexer/rulexer' #must be 1st!!!
require 'rubylexer/version'
require 'rubylexer/token'
require 'rubylexer/charhandler'
require 'rubylexer/symboltable'
#require "io.each_til_charset"
require 'rubylexer/context'
require 'rubylexer/tokenprinter'


#-----------------------------------
class RubyLexer
  include NestedContexts
  

 
   RUBYSYMOPERATORREX=
      %r{^([&|^/%]|=(==?)|=~|>[=>]?|<(<|=>?)?|[+~\-]@?|\*\*?|\[\]=?)}
      # (nasty beastie, eh?)
      #these are the overridable operators
      #does not match flow-control operators like: || && ! or and if not
      #or op= ops like: += -= ||=
      #or .. ... ?:
      #for that use:
   RUBYNONSYMOPERATORREX=
      %r{^([%^/\-+|&]=|(\|\||&&)=?|(<<|>>|\*\*?)=|\.{1,3}|[?:,;]|::|=>?|![=~]?)$}
   RUBYOPERATORREX=/#{RUBYSYMOPERATORREX}|#{RUBYNONSYMOPERATORREX}/o
   UNSYMOPS=/^[~!]$/ #always unary
   UBSYMOPS=/^([*&+-]|::)$/  #ops that could be unary or binary
   WHSPCHARS=WHSPLF+"\\#"
   OPORBEGINWORDLIST=%w(if unless while until)
   BEGINWORDLIST=%w(def class module begin for case do)+OPORBEGINWORDLIST
   OPORBEGINWORDS="(#{OPORBEGINWORDLIST.join '|'})"
   BEGINWORDS=/^(#{BEGINWORDLIST.join '|'})$/o
   FUNCLIKE_KEYWORDLIST=%w/break next redo return yield retry super BEGIN END/
   FUNCLIKE_KEYWORDS=/^(#{FUNCLIKE_KEYWORDLIST.join '|'})$/
   VARLIKE_KEYWORDLIST=%w/__FILE__ __LINE__ false nil self true/
   VARLIKE_KEYWORDS=/^(#{VARLIKE_KEYWORDLIST.join '|'})$/
   INNERBOUNDINGWORDLIST=%w"else elsif ensure in then rescue when"
   INNERBOUNDINGWORDS="(#{INNERBOUNDINGWORDLIST.join '|'})"
   BINOPWORDLIST=%w"and or"
   BINOPWORDS="(#{BINOPWORDLIST.join '|'})"
   NEVERSTARTPARAMLISTWORDS=/\A(#{OPORBEGINWORDS}|#{INNERBOUNDINGWORDS}|#{BINOPWORDS}|end)([^a-zA-Z0-9_!?=]|\Z)/o
   NEVERSTARTPARAMLISTFIRST=CharSet['aoeitrwu']  #chars that begin NEVERSTARTPARAMLIST
   NEVERSTARTPARAMLISTMAXLEN=7     #max len of a NEVERSTARTPARAMLIST
   
   RUBYKEYWORDS=%r{
     ^(alias|#{BINOPWORDS}|defined\?|not|undef|end|
       #{VARLIKE_KEYWORDS}|#{FUNCLIKE_KEYWORDS}|
       #{INNERBOUNDINGWORDS}|#{BEGINWORDS}
     )$
   }xo
      #__END__ should not be in this set... its handled in start_of_line_directives

   CHARMAPPINGS = {
         ?$ => :dollar_identifier,
         ?@ => :at_identifier,
         ?a..?z => :identifier,
         ?A..?Z => :identifier,
         ?_     => :identifier,
         ?0..?9 => :number,
         ?" => :double_quote,        #"
         ?' => :single_quote,        #'
         ?` => :back_quote,          #`

         WHSP => :whitespace, #includes \r
         ?, => :comma,
         ?; => :semicolon,

         ?^ => :caret,
         ?~ => :tilde,
         ?= => :equals,
         ?! => :exclam,
         ?. => :dot,

         #these ones could signal either an op or a term
         ?/ => :regex_or_div,
         "|" => :conjunction_or_goalpost,
         ">" => :quadriop,
         "*&" => :star_or_amp,        #could be unary
         "+-" => :plusminus, #could be unary
         ?< => :lessthan,
         ?% => :percent,
         ?? => :char_literal_or_op,  #single-char int literal
         ?: => :symbol_or_op,
         ?\n => :newline, #implicitly escaped after op
         #?\r => :newline, #implicitly escaped after op

         ?\\ => :escnewline,
         ?\x00 => :eof,
         ?\x04 => :eof,
         ?\x1a => :eof,

         "[({" => :open_brace,
         "])}" => :close_brace,


         ?# => :comment
   }

   attr_reader :incomplete_here_tokens, :parsestack, :last_token_maybe_implicit


   #-----------------------------------
   def initialize(filename,file,linenum=1,offset_adjust=0)
      @offset_adjust=0 #set again in next line
      super(filename,file, linenum,offset_adjust)
      @start_linenum=linenum
      @parsestack=[TopLevelContext.new]
      @incomplete_here_tokens=[] #not used anymore
      @pending_here_bodies=[]
      @localvars_stack=[SymbolTable.new]
      @defining_lvar=nil
      @in_def_name=false
      @last_operative_token=nil
      @last_token_maybe_implicit=nil
      @enable_macro=nil
      @base_file=nil
      @progress_thread=nil

      @toptable=CharHandler.new(self, :illegal_char, CHARMAPPINGS)

      start_of_line_directives
      progress_printer
   end

   def progress_printer
     return unless ENV['RL_PROGRESS']
     $stderr.puts 'printing progresses'
     @progress_thread=Thread.new do
       until EoiToken===@last_operative_token
         sleep 10
         $stderr.puts @file.pos
       end
     end
   end
   
   def localvars;
     @localvars_stack.last
   end

   attr_accessor :in_def
   attr :localvars_stack	
   attr :offset_adjust
   attr_writer :pending_here_bodies

   #-----------------------------------
   def set_last_token(tok)
     @last_operative_token=@last_token_maybe_implicit=tok
   end

   #-----------------------------------
   def get1token
      result=super  #most of the action's here

      if ENV['PROGRESS']
      @last_cp_pos||=0
      @start_time||=Time.now
      if result.offset-@last_cp_pos>100000
        $stderr.puts "#{result.offset} #{Time.now-@start_time}"
        @last_cp_pos=result.offset
      end
      end

      #now cleanup and housekeeping


      #check for bizarre token types
      case result
      when ImplicitParamListStartToken, ImplicitParamListEndToken
          @last_token_maybe_implicit=result
          result
      when StillIgnoreToken#,nil
          result
      when StringToken
          set_last_token result
          assert !(IgnoreToken===@last_operative_token)
          result.elems.map!{|frag|
            if String===frag
              result.translate_escapes(frag)
            else 
              frag
            end
          } if AUTO_UNESCAPE_STRINGS
          result
  
      when Token#,String
          set_last_token result
          assert !(IgnoreToken===@last_operative_token)
          result
      else
          raise "#{@filename}:#{linenum}:token is a #{result.class}, last is #{@last_operative_token}"
      end
   end

   #-----------------------------------
   def eof?
     super or EoiToken===@last_operative_token
   end

   #-----------------------------------
   def input_position
     super+@offset_adjust
   end

   #-----------------------------------
   def input_position_raw 
     @file.pos
   end

   #-----------------------------------
   def balanced_braces?

       #@parsestack.empty?
       @parsestack.size==1 and TopLevelContext===@parsestack.first
   end

   #-----------------------------------
   def dollar_identifier(ch=nil)
      s=eat_next_if(?$) or return nil

      if t=((identifier_as_string(?$) or special_global))
        s << t
      else error= "missing $id name"
      end

      return lexerror(VarNameToken.new(s),error)
   end

   #-----------------------------------
   def at_identifier(ch=nil)
      result =  (eat_next_if(?@) or return nil)
      result << (eat_next_if(?@) or '')
      if t=identifier_as_string(?@)
        result << t
      else error= "missing @id name"
      end
      result=VarNameToken.new(result)
      result.in_def=true if inside_method_def?
      return lexerror(result,error)
   end

private
   #-----------------------------------
   def inside_method_def?
     return true if (defined? @in_def) and @in_def
     @parsestack.reverse_each{|ctx|
       ctx.starter=='def' and ctx.state!=:saw_def and return true
     }
     return false
   end

   #-----------------------------------
   def here_spread_over_ruby_code(rl,tok) #not used anymore
     assert(!rl.incomplete_here_tokens.empty?)
     @incomplete_here_tokens += rl.incomplete_here_tokens
   end

   #-----------------------------------
   def expect_do_or_end_or_nl!(st)
     @parsestack.push ExpectDoOrNlContext.new(st,/(do|;|:|\n)/,@linenum)
   end

  #-----------------------------------
  #match NoWstoken, ws, comment, or (escaped?) newline repeatedly
  def maybe_no_ws_token
    result=[]
    while IgnoreToken===(tok=get1token)
      EoiToken===tok and lexerror tok,"end of file not expected here"
      result << tok
    end
    assert((not IgnoreToken===tok))
    @moretokens.unshift tok
    return result
  end

  #-----------------------------------
  WSCHARSET=/[#\\\n\s\t\v\r\f\x00\x04\x1a]/
  def ignored_tokens(allow_eof=false,allow_eol=true)
    result=[]
    result << @moretokens.shift while StillIgnoreToken===@moretokens.first
    @moretokens.empty? or return result
    loop do
      unless @moretokens.empty?
        case @moretokens.first
        when StillIgnoreToken
        when NewlineToken: allow_eol or break
        else break
        end 
      else
      
        break unless ch=nextchar
        ch=ch.chr
        break unless WSCHARSET===ch
        break if ch[/[\r\n]/] and !allow_eol
      end
      

      tok=get1token
      result << tok
      case tok
        when NewlineToken; assert allow_eol; block_given? and yield tok
        when EoiToken; allow_eof or lexerror tok,"end of file not expected here(2)"
        when StillIgnoreToken
        else raise "impossible token: #{tok.inspect}"
      end
    end

=begin
      @whsphandler||=CharHandler.new(self, :==,
         "#" => :comment,
         "\n" => :newline,
         "\\" => :escnewline,
         "\s\t\v\r\f" => :whitespace
      )
      #tok=nil
      while tok=@whsphandler.go((nextchar or return result))
         block_given? and NewlineToken===tok and yield tok
         result << tok
      end
=end
    return result
  end

   #-----------------------------------
   def safe_recurse
      old_moretokens=@moretokens
      #old_parsestack=@parsestack.dup
      @moretokens=[]
      result=   yield @moretokens
      #assert @incomplete_here_tokens.empty?
      #assert @parsestack==old_parsestack
      @moretokens= old_moretokens.concat @moretokens
      return result
      #need to do something with @last_operative_token?
   end

   #-----------------------------------
   def special_global   #handle $-a and friends
      assert prevchar=='$'
      result = ((
      #order matters here, but it shouldn't
      #(but til_charset must be last)
         eat_if(/-[a-z0-9_]/i,2) or
         eat_next_if(/[!@&+`'=~\-\/\\,.;<>*"$?:]/) or
         (?0..?9)===nextchar ? til_charset(/[^\d]/) : nil
      ))
   end

   #-----------------------------------
   def identifier(context=nil)
      oldpos= input_position
      str=identifier_as_string(context)

      #skip keyword processing if 'escaped' as it were, by def, . or ::
      #or if in a non-bare context
      #just asserts because those contexts are never encountered.
      #control goes through symbol(<...>,nil) 
      assert( /^[a-z_]$/i===context)
      assert MethNameToken===@last_operative_token || !(@last_operative_token===/^(\.|::|(un)?def|alias)$/)

      @moretokens.unshift(*parse_keywords(str,oldpos) do |tok|
        #if not a keyword,
        case str
          when FUNCLIKE_KEYWORDS; except=tok
          when VARLIKE_KEYWORDS,RUBYKEYWORDS; raise "shouldnt see keywords here, now"
        end
        was_last=@last_operative_token
        @last_operative_token=tok if tok
        normally=safe_recurse { |a| var_or_meth_name(str,was_last,oldpos,after_nonid_op?{true}) }
        (Array===normally ? normally[0]=except : normally=except) if except
        normally
      end)
      return @moretokens.shift
   end

   #-----------------------------------
   IDENTREX={}
   def identifier_as_string(context)
      #must begin w/ letter or underscore
      #char class needs changing here for utf8 support
      /[_a-z]/i===nextchar.chr or return

      #equals, question mark, and exclamation mark
      #might be allowed at the end in some contexts.
      #(in def headers and symbols)
      #otherwise, =,?, and ! are to be considered
      #separate tokens. confusing, eh?
      #i hope i've captured all right conditions....
      #context should always be ?: right after def, ., and :: now

      #= and ! only match if not part of a larger operator
      trailers = 
        case context
         when ?@,?$ then ""
#         when ?:    then "!(?![=])|\\?|=(?![=~>])"
         else            "!(?![=])|\\?"
        end      
      @in_def_name||context==?: and trailers<<"|=(?![=~>])"

      @file.scan(IDENTREX[trailers]||=/^(?>[_a-z][a-z0-9_]*(?:#{trailers})?)/i)
   end

  #-----------------------------------
  #contexts in which comma may appear in ruby:
    #multiple lhs (terminated by assign op)
    #multiple rhs (in implicit context) 
    #method actual param list (in ( or implicit context)
    #method formal param list (in ( or implicit context)
    #block  formal param list (in | context) 
    #nested multiple rhs 
    #nested multiple lhs 
    #nested block formal list 
    #element reference/assignment (in [] or []= method actual parameter context)
    #hash immediate (in imm{ context)
    #array immediate (in imm[ context)
    #list between 'for' and 'in'
    #list after rescue
    #list after when
    #list after undef

    #note: comma in parens not around a param list or lhs or rhs is illegal

   #-----------------------------------
   #a comma has been seen. are we in an
   #lvalue list or some other construct that uses commas?
   def comma_in_lvalue_list?
     @parsestack.last.lhs=
       case l=@parsestack.last
       when ListContext:
       when DefContext: l.in_body
       else true
       end
   end
   
   #-----------------------------------
   def in_lvar_define_state lasttok=@last_operative_token
     #@defining_lvar is a hack
     @defining_lvar or case ctx=@parsestack.last
       #when ForSMContext; ctx.state==:for
       when RescueSMContext
         lasttok.ident=="=>" and @file.match?( /\A[\s\v]*([:;#\n]|then[^a-zA-Z0-9_])/m )
       #when BlockParamListLhsContext; true
     end 
   end

   IMPLICIT_PARENS_BEFORE_ACCESSOR_ASSIGNMENT=2
   
   #-----------------------------------
   #determine if an alphabetic identifier refers to a variable
   #or method name. generates implicit parenthes(es) if it is a
   #call site and no explicit parens are present. starts an implicit param list
   #if appropriate. adds tok to the
   #local var table if its a local var being defined for the first time.
   
   #in general, operators in ruby are disambuated by the before-but-not-after rule.
   #an otherwise ambiguous operator is disambiguated by the surrounding whitespace:
   #whitespace before but not after the 'operator' indicates it is to be considered a
   #value token instead. otherwise it is a binary operator. (unary (prefix) ops count 
   #as 'values' here.)
   def var_or_meth_name(name,lasttok,pos,was_after_nonid_op)
     #look for call site if not a keyword or keyword is function-like
     #look for and ignore local variable names

     assert String===name
     
     was_in_lvar_define_state=in_lvar_define_state(lasttok)
     #maybe_local really means 'maybe local or constant'
     maybe_local=case name
       when /[^a-z_0-9]$/i #do nothing
       when /^[a-z_]/  
         (localvars===name or 
          VARLIKE_KEYWORDS===name or 
          was_in_lvar_define_state
         ) and not lasttok===/^(\.|::)$/
       when /^[A-Z]/
         is_const=true
         not lasttok==='.'  #this is the right algorithm for constants... 
     end 
          
     assert(@moretokens.empty?)
     
     oldlast=@last_operative_token

     tok=set_last_token assign_lvar_type!(VarNameToken.new(name,pos))

     oldpos= input_position
     sawnl=false
     result=ws_toks=ignored_tokens(true) {|nl| sawnl=true }
     if sawnl || eof? 
         if was_in_lvar_define_state
           if /^[a-z_][a-zA-Z_0-9]*$/===name 
             assert !(lasttok===/^(\.|::)$/)
             localvars[name]=true
           end
           return result.unshift(tok)
         elsif maybe_local
           return result.unshift(tok) #if is_const
         else 
           return result.unshift(
             MethNameToken.new(name,pos),  #insert implicit parens right after tok
             ImplicitParamListStartToken.new( oldpos),
             ImplicitParamListEndToken.new( oldpos) 
           )
         end
     end
     
     #if next op is assignment (or comma in lvalue list)
     #then omit implicit parens
     assignment_coming=case nc=nextchar
       when ?=;  not /^=[>=~]$/===readahead(2)
       when ?,; comma_in_lvalue_list? 
       when ?); last_context_not_implicit.lhs
       when ?i; /^in[^a-zA-Z_0-9]/===readahead(3) and 
                  ForSMContext===last_context_not_implicit
       when ?>,?<; /^(.)\1=$/===readahead(3)
       when ?*,?&; /^(.)\1?=/===readahead(3)
       when ?|; /^\|\|?=/===readahead(3) or
                #is it a goalpost?
                BlockParamListLhsContext===last_context_not_implicit &&
                readahead(2)[1] != ?|
       when ?%,?/,?-,?+,?^; readahead(2)[1]== ?=
     end 
     if (assignment_coming && !(lasttok===/^(\.|::)$/) or was_in_lvar_define_state)
        tok=assign_lvar_type! VarNameToken.new(name,pos)
        if /[^a-z_0-9]$/i===name 
        elsif /^[a-z_]/===name and !(lasttok===/^(\.|::)$/)
          localvars[name]=true
        end
        return result.unshift(tok)
     end
     
     implicit_parens_to_emit=
     if assignment_coming
       @parsestack.push AssignmentContext.new(nil) if nc==?% or nc==?/
       IMPLICIT_PARENS_BEFORE_ACCESSOR_ASSIGNMENT
     else
     case nc
       when nil: 2
       when ?!; /^![=~]$/===readahead(2) ? 2 : 1
       when ?d; 
         if /^do([^a-zA-Z0-9_]|$)/===readahead(3)
           if maybe_local and expecting_do?
             ty=VarNameToken 
             0
           else 
             maybe_local=false
             2 
           end
         else 
           1
         end
       when NEVERSTARTPARAMLISTFIRST
         (NEVERSTARTPARAMLISTWORDS===readahead(NEVERSTARTPARAMLISTMAXLEN)) ? 2 : 1
       when ?",?',?`,?a..?z,?A..?Z,?0..?9,?_,?@,?$,?~; 1 #"
       when ?{
         maybe_local=false
         1
=begin
         x=2
         x-=1 if /\A(return|break|next)\Z/===name and 
                 !(KeywordToken===oldlast and oldlast===/\A(\.|::)\Z/)
         x
=end
       when ?(
         maybe_local=false
         lastid=lasttok&&lasttok.ident
         case lastid
           when /\A[;(]|do\Z/: was_after_nonid_op=false
           when '|':  was_after_nonid_op=false unless BlockParamListLhsContext===@parsestack.last
           when '{': was_after_nonid_op=false if  BlockContext===@parsestack.last or BeginEndContext===@parsestack.last
         end if KeywordToken===lasttok
         was_after_nonid_op=false if NewlineToken===lasttok or lasttok.nil?
         want_parens=!(ws_toks.empty? or was_after_nonid_op) #or
#                      /^(::|rescue|yield|else|case|when|if|unless|until|while|and|or|&&|\|\||[?:]|\.\.?\.?|=>)$/===lastid or 
#                      MethNameToken===lasttok or
#                      RUBYNONSYMOPERATORREX===lastid && /=$/===lastid && '!='!=lastid
#                     )

         #look ahead for closing paren (after some whitespace...)
         want_parens=false if @file.match?( /\A.(?:\s|\v|\#.*\n)*\)/ )
#         afterparen=@file.pos
#         getchar
#         ignored_tokens(true)
#         want_parens=false if nextchar==?)
#         @file.pos=afterparen
         want_parens=true if /^(return|break|next)$/===@last_operative_token.ident and not(
              KeywordToken===lasttok and /^(\.|::)$/===lasttok.ident
            )
         want_parens ? 1 : 0
       when ?},?],?),?;,(?^ unless @enable_macro), ?|, ?>, ?,, ?., ?=; 2
       when ?+, ?-, ?%, ?/, (?^ if @enable_macro)
         if /^(return|break|next)$/===@last_operative_token.ident and not(
              KeywordToken===lasttok and /^(\.|::)$/===lasttok.ident
            )
           1 
         else
           (ws_toks.empty? || readahead(2)[/^.[#{WHSPLF}]/o]) ? 2 : 3
         end
       when ?*, ?&
 #        lasttok=@last_operative_token
         if /^(return|break|next)$/===@last_operative_token.ident and not(
              KeywordToken===lasttok and /^(\.|::)$/===lasttok.ident
            )
           1 
         else
           (ws_toks.empty? || readahead(2)[/^.[#{WHSPLF}*&]/o]) ? 2 : 3
         end
       when ?:
         next2=readahead(2)
         if /^:(?:[#{WHSPLF}]|(:))$/o===next2 then 
           $1 && !ws_toks.empty?   ? 3 : 2 
         else 
           3 
         end
       when ??; next3=readahead(3);
                   /^\?([#{WHSPLF}]|[a-z_][a-z_0-9])/io===next3 ? 2 : 3
#       when ?:,??; (readahead(2)[/^.[#{WHSPLF}]/o]) ? 2 : 3
       when ?<; (!ws_toks.empty? && readahead(4)[/^<<-?["'`a-zA-Z_0-9]/]) ? 3 : 2 
       when ?[; 
           if ws_toks.empty? 
             (KeywordToken===oldlast and /^(return|break|next)$/===oldlast.ident) ? 3 : 2
           else
             3
           end
       when ?\\, ?\s, ?\t, ?\n, ?\r, ?\v, ?#; raise 'failure'
       else raise "unknown char after ident: #{nc=nextchar ? nc.chr : "<<EOF>>"}"
     end
     end

     if is_const and implicit_parens_to_emit==3 then #needed?
       implicit_parens_to_emit=1
     end
     
     if maybe_local and implicit_parens_to_emit>=2 
       implicit_parens_to_emit=0
       ty=VarNameToken
     else
       ty||=MethNameToken
     end
     tok=assign_lvar_type!(ty.new(name,pos))
     
     
     case implicit_parens_to_emit
     when 2;
       result.unshift ImplicitParamListStartToken.new(oldpos),
                 ImplicitParamListEndToken.new(oldpos)
     when 1,3;
       arr,pass=*param_list_coming_with_2_or_more_params?
       result.push( *arr )
       unless pass
         #only 1 param in list
         result.unshift ImplicitParamListStartToken.new(oldpos)
         last=result.last
         last.set_callsite! false if last.respond_to? :callsite? and last.callsite? #KeywordToken===last and last.ident==')'
         if /^(break|next|return)$/===name and 
            !(KeywordToken===lasttok and /^(\.|::)$/===lasttok.ident)
           ty=KWParamListContextNoParen 
         else
           ty=ParamListContextNoParen
         end
         @parsestack.push ty.new(@linenum)
       end
     when 0; #do nothing
     else raise 'invalid value of implicit_parens_to_emit'
     end
     return result.unshift(tok)
     # 'ok:'
     # 'if unless while until {'
     # '\n (unescaped) and or'
     # 'then else elsif rescue ensure (illegal in value context)'

     # 'need to pop noparen from parsestack on these tokens: (in operator context)'
     # 'not ok:'
     # 'not (but should it be?)'
   end

   #-----------------------------------
   def param_list_coming_with_2_or_more_params?
     WHSPCHARS[prevchar] && (?(==nextchar) or return [[],false]
       basesize=@parsestack.size
       result=[get1token]
       pass=loop{
         tok=get1token
         result << tok
         if @parsestack.size==basesize
           break false
         elsif ','==tok.to_s and @parsestack.size==basesize+1
           break true 
         elsif OperatorToken===tok and /^[&*]$/===tok.ident and tok.unary and @parsestack.size==basesize+1
           break true 
         elsif EoiToken===tok
           lexerror tok, "unexpected eof in parameter list"
         end
       }
       return [result,pass]
   end

  #-----------------------------------
  CONTEXT2ENDTOK={
    AssignmentRhsContext=>AssignmentRhsListEndToken, 
    ParamListContextNoParen=>ImplicitParamListEndToken,
    KWParamListContextNoParen=>ImplicitParamListEndToken, #break,next,return
    WhenParamListContext=>KwParamListEndToken, 
    RescueSMContext=>KwParamListEndToken
  }
  def abort_noparens!(str='')
    #assert @moretokens.empty?
    result=[]
    while klass=CONTEXT2ENDTOK[@parsestack.last.class]
      result << klass.new(input_position-str.length)
      break if RescueSMContext===@parsestack.last #and str==':'
      break if WhenParamListContext===@parsestack.last and str==':'
      @parsestack.pop 
    end
    return result
  end

  #-----------------------------------
  CONTEXT2ENDTOK_FOR_RESCUE={
    AssignmentRhsContext=>AssignmentRhsListEndToken, 
    ParamListContextNoParen=>ImplicitParamListEndToken,
    KWParamListContextNoParen=>ImplicitParamListEndToken,
    WhenParamListContext=>KwParamListEndToken,      #I think this isn't needed...
    RescueSMContext=>KwParamListEndToken
  }
  def abort_noparens_for_rescue!(str='')
    #assert @moretokens.empty?
    result=[]
    ctx=@parsestack.last
    while klass=CONTEXT2ENDTOK_FOR_RESCUE[ctx.class]
      break if AssignmentRhsContext===ctx && !ctx.multi_assign? 
      if ParamListContextNoParen===ctx && AssignmentRhsContext===@parsestack[-2]
        result.push ImplicitParamListEndToken.new(input_position-str.length),
                    AssignmentRhsListEndToken.new(input_position-str.length)
          @parsestack.pop
          @parsestack.pop
        break
      end
      result << klass.new(input_position-str.length) #unless AssignmentRhsContext===ctx and !ctx.multi_assign?
      break if RescueSMContext===ctx #why is this here?
      @parsestack.pop 
      ctx=@parsestack.last
    end
    return result
  end

  #-----------------------------------
  CONTEXT2ENDTOK_FOR_DO={
    AssignmentRhsContext=>AssignmentRhsListEndToken, 
    ParamListContextNoParen=>ImplicitParamListEndToken,
    ExpectDoOrNlContext=>1,
    #WhenParamListContext=>KwParamListEndToken,
    #RescueSMContext=>KwParamListEndToken
  }
  def abort_noparens_for_do!(str='')
    #assert @moretokens.empty?
    result=[]
    while klass=CONTEXT2ENDTOK_FOR_DO[@parsestack.last.class]
      break if klass==1
      result << klass.new(input_position-str.length)
      @parsestack.pop 
    end
    return result
  end

  #-----------------------------------
  def expecting_do?
    @parsestack.reverse_each{|ctx|
      next if AssignmentRhsContext===ctx
      return !!CONTEXT2ENDTOK_FOR_DO[ctx.class]
    }
    return false
  end

   #-----------------------------------
   def abort_1_noparen!(offs=0)
     assert @moretokens.empty?
     result=[]
     while AssignmentRhsContext===@parsestack.last
       @parsestack.pop
       result << AssignmentRhsListEndToken.new(input_position-offs)
     end
     if ParamListContextNoParen===@parsestack.last #or lexerror huh,'{} with no matching callsite'
       @parsestack.pop
       result << ImplicitParamListEndToken.new(input_position-offs)
     end
     return result
   end

   #-----------------------------------
   def enable_macros!
     @enable_macro="macro"
     class <<self
       alias keyword_macro keyword_def
     end
   end
   public :enable_macros!


   #-----------------------------------
   @@SPACES=/[\ \t\v\f\v]/
   @@WSTOK=/\r?\n|\r*#@@SPACES+(?:#@@SPACES|\r(?!\n))*|\#[^\n]*\n|\\\r?\n|
            ^=begin[\s\n](?:(?!=end).*\n)*=end[\s\n].*\n/x
   @@WSTOKS=/(?!=begin)#@@WSTOK+/o
   def divide_ws(ws,offset)
     result=[]
     ws.scan(/\G#@@WSTOK/o){|ws|
       incr= $~.begin(0)
       klass=case ws
       when /\A[\#=]/: CommentToken
       when /\n\Z/: EscNlToken
       else WsToken
       end
       result << klass.new(ws,offset+incr)
     }
     result.each_with_index{|ws,i|
       if WsToken===ws
         ws.ident << result.delete(i+1).ident while WsToken===result[i+1]
       end
     }
     return result
   end
   


   #-----------------------------------
   #parse keywords now, to prevent confusion over bare symbols
   #and match end with corresponding preceding def or class or whatever.
   #if arg is not a keyword, the block is called
   def parse_keywords(str,offset,&block)
      assert @moretokens.empty?
      assert !(KeywordToken===@last_operative_token and /A(\.|::|def)\Z/===@last_operative_token.ident)
      result=[KeywordToken.new(str,offset)]

      m="keyword_#{str}"
      respond_to?(m) ? (send m,str,offset,result,&block) : block[MethNameToken.new(str)]
   end
   public #these have to be public so respond_to? can see them (sigh)
   def keyword_end(str,offset,result)
         result.unshift(*abort_noparens!(str))
         @parsestack.last.see self,:semi #sorta hacky... should make an :end event instead?

=begin not needed?
         if ExpectDoOrNlContext===@parsestack.last
            @parsestack.pop
            assert @parsestack.last.starter[/^(while|until|for)$/]
         end
=end

         WantsEndContext===@parsestack.last or lexerror result.last, 'unbalanced end'
         ctx=@parsestack.pop
         start,line=ctx.starter,ctx.linenum
         BEGINWORDS===start or lexerror result.last, "end does not match #{start or "nil"}"
         /^(do)$/===start and localvars.end_block
         /^(class|module|def)$/===start and @localvars_stack.pop
         return result
   end

   def keyword_module(str,offset,result) 
         result.first.has_end!
         @parsestack.push WantsEndContext.new(str,@linenum)
         @localvars_stack.push SymbolTable.new 
         offset=input_position
         @file.scan(/\A(#@@WSTOKS)?(::)?/o) 
         md=@file.last_match
         all,ws,dc=*md
         fail if all.empty?
         @moretokens.concat divide_ws(ws,offset) if ws
         @moretokens.push KeywordToken.new('::',offset+md.end(0)-2) if dc
         loop do
           offset=input_position
           @file.scan(/\A(#@@WSTOKS)?([A-Z][a-zA-Z_0-9]*)(::)?/o)
           #this regexp---^ will need to change in order to support utf8 properly.
           md=@file.last_match
           all,ws,name,dc=*md
           if ws
             @moretokens.concat divide_ws(ws,offset)
             incr=ws.size
           else
             incr=0
           end
           @moretokens.push VarNameToken.new(name,offset+incr)
           break unless dc
           @moretokens.push NoWsToken.new(offset+md.end(0)-2)
           @moretokens.push KeywordToken.new('::',offset+md.end(0)-2)
         end
         @moretokens.push EndHeaderToken.new(input_position)
         return result
   end        
        

   def keyword_class(str,offset,result)
         result.first.has_end!
         @parsestack.push ClassContext.new(str,@linenum)
         return result
   end

         
   def keyword_if(str,offset,result)  #could be infix form without end
         if after_nonid_op?{false} #prefix form
            result.first.has_end!
            @parsestack.push WantsEndContext.new(str,@linenum)
            @parsestack.push ExpectThenOrNlContext.new(str,@linenum)
         else #infix form
           result.unshift(*abort_noparens!(str))
         end
         return result
   end
   alias keyword_unless keyword_if

   def keyword_elsif(str,offset,result) 
         result.unshift(*abort_noparens!(str))
         @parsestack.push ExpectThenOrNlContext.new(str,@linenum)
         return result
   end
   def keyword_begin(str,offset,result)   
         result.first.has_end!
         @parsestack.push WantsEndContext.new(str,@linenum)
         return result
   end

   alias keyword_case keyword_begin
   def keyword_while(str,offset,result) #could be infix form without end
         if after_nonid_op?{false} #prefix form
           result.first.has_end!
           @parsestack.push WantsEndContext.new(str,@linenum)
           expect_do_or_end_or_nl! str

         else #infix form
           result.unshift(*abort_noparens!(str))
         end
         return result
   end

   alias keyword_until keyword_while

   def keyword_for(str,offset,result)
         result.first.has_end!
         result.push KwParamListStartToken.new(offset+str.length)
         # corresponding EndToken emitted leaving ForContext ("in" branch, below)
         @parsestack.push WantsEndContext.new(str,@linenum)
         #expect_do_or_end_or_nl! str #handled by ForSMContext now
         @parsestack.push ForSMContext.new(@linenum)
         return result
   end
   def keyword_do(str,offset,result)
         result.unshift(*abort_noparens_for_do!(str))
         if ExpectDoOrNlContext===@parsestack.last
            @parsestack.pop
            assert WantsEndContext===@parsestack.last
            result.last.as=";"
         else
            result.last.has_end!
            @parsestack.push WantsEndContext.new(str,@linenum)
            localvars.start_block
            block_param_list_lookahead
         end
         return result
   end
   def keyword_def(str,offset,result)         #macros too, if enabled
         result.first.has_end!
         @parsestack.push ctx=DefContext.new(@linenum)
         ctx.state=:saw_def
      old_moretokens=@moretokens
      @moretokens=[]
      aa=@moretokens
         #safe_recurse { |aa|
            set_last_token KeywordToken.new(str) #hack
            result.concat ignored_tokens

            #read an expr like a.b.c or a::b::c
            #or (expr).b.c
            if nextchar==?( #look for optional parenthesised head
              old_size=@parsestack.size
              parencount=0
              begin
                tok=get1token
                case tok
                when/^\($/.token_pat then parencount+=1
                when/^\)$/.token_pat then parencount-=1
                end
                EoiToken===tok and lexerror tok, "eof in def header"
                result << tok
              end until  parencount==0 #@parsestack.size==old_size
              @localvars_stack.push SymbolTable.new
           else #no parentheses, all tail
             set_last_token KeywordToken.new(".") #hack hack
              tokindex=result.size
              result << tok=symbol(false,false)
              name=tok.to_s
              assert !in_lvar_define_state
     
              #maybe_local really means 'maybe local or constant'
              maybe_local=case name
                when /[^a-z_0-9]$/i; #do nothing
                when /^[@$]/; true
                when VARLIKE_KEYWORDS,FUNCLIKE_KEYWORDS; ty=KeywordToken
                when /^[a-z_]/;  localvars===name 
                when /^[A-Z]/; is_const=true  #this is the right algorithm for constants... 
              end
              result.push(  *ignored_tokens(false,false)  )
              nc=nextchar
              if !ty and maybe_local
                if nc==?: || nc==?.
                  ty=VarNameToken
                end
              end  
              if ty.nil? or (ty==KeywordToken and nc!=?: and nc!=?.)
                   ty=MethNameToken
                   if nc != ?(
                     endofs=tok.offset+tok.to_s.length
                     newtok=ImplicitParamListStartToken.new(endofs)
                     result.insert tokindex+1, newtok
                   end
              end

              assert result[tokindex].equal?(tok)
              var=assign_lvar_type! ty.new(tok.to_s,tok.offset)
              @localvars_stack.push SymbolTable.new
              var.in_def=true if inside_method_def? and var.respond_to? :in_def=
              result[tokindex]=var
              

              #if a.b.c.d is seen, a, b and c
              #should be considered maybe varname instead of methnames.
              #the last (d in the example) is always considered a methname;
              #it's what's being defined.
              #b and c should be considered varnames only if 
              #they are capitalized and preceded by :: .
              #a could even be a keyword (eg self or block_given?).
            end
            #read tail: .b.c.d etc
            result.reverse_each{|res| break set_last_token( res ) unless StillIgnoreToken===res}
            assert !(IgnoreToken===@last_operative_token)
            state=:expect_op
            @in_def_name=true
            while true

               #look for start of parameter list
               nc=(@moretokens.empty? ? nextchar.chr : @moretokens.first.to_s[0,1])
               if state==:expect_op and /^[a-z_(&*]/i===nc
                  ctx.state=:def_param_list
                  list,listend=def_param_list
                  result.concat list
                  end_index=result.index(listend)
                  ofs=listend.offset
                  if endofs
                    result.insert end_index,ImplicitParamListEndToken.new(ofs)
                  else 
                    ofs+=listend.to_s.size
                  end
                  result.insert end_index+1,EndHeaderToken.new(ofs)
                  break
               end

               tok=get1token
               result<< tok
               case tok
               when EoiToken
                  lexerror tok,'unexpected eof in def header'
               when StillIgnoreToken
               when MethNameToken ,VarNameToken # /^[a-z_]/i.token_pat
                  lexerror tok,'expected . or ::' unless state==:expect_name
                  state=:expect_op
               when /^(\.|::)$/.token_pat
                  lexerror tok,'expected ident' unless state==:expect_op
                  if endofs
                    result.insert( -2, ImplicitParamListEndToken.new(endofs) )
                    endofs=nil
                  end
                  state=:expect_name
               when /^(;|end)$/.token_pat, NewlineToken #are we done with def name?
                  ctx.state=:def_body
                  state==:expect_op or lexerror tok,'expected identifier'
                  if endofs
                    result.insert( -2,ImplicitParamListEndToken.new(tok.offset) )
                  end
                  result.insert( -2, EndHeaderToken.new(tok.offset) )
                  break
               else
                  lexerror(tok, "bizarre token in def name: " +
                           "#{tok}:#{tok.class}")
               end
            end
            @in_def_name=false
         #}
      @moretokens= old_moretokens.concat @moretokens
         return result
   end
   def keyword_alias(str,offset,result)
         safe_recurse { |a|
            set_last_token KeywordToken.new( "alias" )#hack
            result.concat ignored_tokens
            res=symbol(eat_next_if(?:),false) 
            unless res
              lexerror(result.first,"bad symbol in alias")
            else
              res.ident[0]==?$ and res=VarNameToken.new(res.ident,res.offset)
              result<< res
              set_last_token KeywordToken.new( "alias" )#hack
              result.concat ignored_tokens
              res=symbol(eat_next_if(?:),false) 
              unless res
                lexerror(result.first,"bad symbol in alias")
              else
                res.ident[0]==?$ and res=VarNameToken.new(res.ident,res.offset)
                result<< res
              end
            end
         }
         return result
   end
   def keyword_undef(str,offset,result)
         safe_recurse { |a|
            loop do
               set_last_token KeywordToken.new( "," )#hack
               result.concat ignored_tokens
               tok=symbol(eat_next_if(?:),false)
               tok or lexerror(result.first,"bad symbol in undef")
               result<< tok
               set_last_token tok
               assert !(IgnoreToken===@last_operative_token)

               sawnl=false
               result.concat ignored_tokens(true){|nl| sawnl=true}

               break if sawnl or nextchar != ?,
               tok= single_char_token(?,)
               result<< tok
            end
         }
         
         return result
   end
#      when "defined?"
         #defined? might have a baresymbol following it
         #does it need to be handled specially?
         #it would seem not.....

   def keyword_when(str,offset,result)
         #abort_noparens! emits EndToken on leaving context
         result.unshift(*abort_noparens!(str))
         result.push KwParamListStartToken.new( offset+str.length)
         @parsestack.push WhenParamListContext.new(str,@linenum)
         return result
   end

   def keyword_rescue(str,offset,result)
         unless after_nonid_op? {false}
           #rescue needs to be treated differently when in operator context... 
           #i think no RescueSMContext should be pushed on the stack...
           result.first.set_infix!            #plus, the rescue token should be marked as infix
           result.unshift(*abort_noparens_for_rescue!(str))  
         else         
           result.push KwParamListStartToken.new(offset+str.length)
           #corresponding EndToken emitted by abort_noparens! on leaving rescue context
           @parsestack.push RescueSMContext.new(@linenum)
           result.unshift(*abort_noparens!(str))  
         end
         return result
   end

   def keyword_then(str,offset,result)
         result.unshift(*abort_noparens!(str))
         @parsestack.last.see self,:then

         if ExpectThenOrNlContext===@parsestack.last
           @parsestack.pop
         else #error... does anyone care?
         end
         return result
   end
         
   def keyword_in(str,offset,result)
         result.unshift KwParamListEndToken.new( offset)
         result.unshift(*abort_noparens!(str))
         @parsestack.last.see self,:in
         return result
   end
         
   def _keyword_innerbounding(str,offset,result)
         result.unshift(*abort_noparens!(str))
         return result
   end
   for kw in BINOPWORDLIST+INNERBOUNDINGWORDLIST-["in","then","rescue","when","elsif"]
     alias_method "keyword_#{kw}".to_sym, :_keyword_innerbounding
   end

   def keyword_return(str,offset,result)     
         fail if KeywordToken===@last_operative_token and @last_operative_token===/\A(\.|::)\Z/
         tok=KeywordToken.new(str,offset)
         result=yield tok
         result[0]=tok
         tok.has_no_block!
         return result
   end

   alias keyword_break keyword_return
   alias keyword_next keyword_return
    
     
   def keyword_END(str,offset,result)
         #END could be treated, lexically, just as if it is an
         #ordinary method, except that local vars created in
         #END blocks are visible to subsequent code. (Why??) 
         #That difference forces a custom parsing.
         if @last_operative_token===/^(\.|::)$/
           result=yield MethNameToken.new(str) #should pass a methname token here
         else
           safe_recurse{
             old=result.first
             result=[
               KeywordToken.new(old.ident,old.offset),
               ImplicitParamListStartToken.new(input_position),
               ImplicitParamListEndToken.new(input_position),
               *ignored_tokens
             ]
             getchar=='{' or lexerror(result.first,"expected { after #{str}")
             result.push KeywordToken.new('{',input_position-1)
             result.last.set_infix!
             result.last.as="do"
             @parsestack.push BeginEndContext.new(str,offset)
           }
         end
         return result
   end


   def _keyword_funclike(str,offset,result)
         if @last_operative_token===/^(\.|::)$/
           result=yield MethNameToken.new(str) #should pass a methname token here
         else
           result=yield KeywordToken.new(str)
         end
         return result
   end
   for kw in FUNCLIKE_KEYWORDLIST-["END","return","break","next"] do
     alias_method "keyword_#{kw}".to_sym, :_keyword_funclike
   end
 
   def _keyword_varlike(str,offset,result)
         #do nothing
         return result
   end
   for kw in VARLIKE_KEYWORDLIST+["defined?", "not"] do
     alias_method "keyword_#{kw}".to_sym, :_keyword_varlike
   end

   private

   #-----------------------------------
   def parsestack_lastnonassign_is?(obj)
     @parsestack.reverse_each{|ctx|
       case ctx
  #    when klass: return true
       when AssignmentRhsContext
       else return ctx.object_id==obj.object_id
       end
     }
   end

   #-----------------------------------
   #what's inside goalposts (the block formal parameter list) 
   #is considered the left hand side of an assignment.
   #inside goalposts, a local variable is declared if
   #it has one of the following tokens on both sides:
   #   ,  (if directly inside goalposts or nested lhs) 
   #   |  (as a goalpost)
   #   * or & (unary only)
   #   ( or ) (if they form a nested left hand side)
   #parens form a nested lhs if they're not part of an actual
   #parameter list and have a comma directly in them somewhere
   #a nested lhs _must_ have a comma in it somewhere. this is
   #not legal:
   #  (foo)=[1]
   #whereas this is:
   #  (foo,)=[1]


   
   #-----------------------------------
   def block_param_list_lookahead
      safe_recurse{ |la|
         set_last_token KeywordToken.new(  ';' )
         a=ignored_tokens

         if eat_next_if(?|)
           a<< KeywordToken.new("|", input_position-1)
if true
           @parsestack.push mycontext=BlockParamListLhsContext.new(@linenum)
           nextchar==?| and a.push NoWsToken.new(input_position)
else
           if eat_next_if(?|)
             a.concat [NoWsToken.new(input_position-1),
                       KeywordToken.new('|', input_position-1)]
           else
             assert !@defining_lvar
             @defining_lvar=true
             assert((@last_operative_token===';' or NewlineToken===@last_operative_token))
             @parsestack.push mycontext=BlockParamListLhsContext.new(@linenum)
             #block param initializers ARE supported here, even tho ruby doesn't allow them!
             tok=nil
             loop do
               tok=get1token
               case tok
               when EoiToken; lexerror tok,"eof in block parameter list"
               when AssignmentRhsListStartToken; @defining_lvar=false
               when AssignmentRhsListEndToken; parsestack_lastnonassign_is?(mycontext) and @defining_lvar=true
               end
               
               tok==='|' and parsestack_lastnonassign_is?(mycontext) and break
               a<< tok
             end 
             assert@defining_lvar || AssignmentRhsContext===@parsestack.last
             @defining_lvar=false
             while AssignmentRhsContext===@parsestack.last 
               a.push( *abort_noparens!('|') )
             end
             
             @parsestack.last.object_id==mycontext.object_id or raise 'expected my BlockParamListLhsContext atop @parsestack'
             @parsestack.pop
             
             a<< KeywordToken.new('|',tok.offset)
             @moretokens.empty? or
               fixme %#moretokens might be set from get1token call above...might be bad#
end
           end
         end

         set_last_token KeywordToken.new( ';' )
         #a.concat ignored_tokens

         #assert @last_operative_token===';'
         #a<<get1token

         la[0,0]=a
      }
   end

   #-----------------------------------
   #handle parameter list of a method declaration.
   #parentheses are optional... if missing param list
   #is ended by (unescaped) newline or semicolon (at the same bracing level)
   #expect a brace as the next token,
   #then match the following tokens until
   #the matching endbrace is found
   def def_param_list
      @in_def_name=false
      result=[]
      normal_comma_level=old_parsestack_size=@parsestack.size
      listend=nil
      safe_recurse { |a|
         assert(@moretokens.empty?)
         assert((not IgnoreToken===@moretokens[0]))
         assert((@moretokens[0] or not nextchar.chr[WHSPCHARS]))

         #have parentheses?
         if '('==@moretokens[0] or nextchar==?(
            #get open paren token
            result.concat maybe_no_ws_token
            result << tok=get1token
            assert(tok==='(')


            #parsestack was changed by get1token above...
            normal_comma_level+=1
            assert(normal_comma_level==@parsestack.size)
            endingblock=proc{|tok| tok===')' }
         else
            endingblock=proc{|tok| tok===';' or NewlineToken===tok}
         end
         class << endingblock
            alias === call
         end

         set_last_token KeywordToken.new( ',' )#hack
         #read local parameter names
         nextvar=nil
         loop do
            expect_name=(@last_operative_token===',' and
                         normal_comma_level==@parsestack.size)
            expect_name and @defining_lvar||=true
            result << tok=get1token
            break lexerror(tok, "unexpected eof in def header") if EoiToken===tok

            #break if at end of param list
            if endingblock===tok and old_parsestack_size>=@parsestack.size
              nextvar and localvars[nextvar]=true #add nextvar to local vars
              listend=tok
              break
            end

            #next token is a local var name
            #(or the one after that if unary ops present)
            #result.concat ignored_tokens
            if expect_name 
              case tok
                when IgnoreToken #, /^[A-Z]/ #do nothing
                when /^,$/.token_pat #hack
                              
                when VarNameToken
                  assert@defining_lvar
                  @defining_lvar=false
                  assert((not @last_operative_token===','))
#                  assert !nextvar
                  nextvar=tok.ident
                  localvars[nextvar]=false #remove nextvar from list of local vars for now
                when /^[&*]$/.token_pat #unary form...
                  #a NoWsToken is also expected... read it now
                  result.concat maybe_no_ws_token #not needed?
                  set_last_token KeywordToken.new( ',' )
                else 
                  lexerror tok,"unfamiliar var name '#{tok}'"
              end
            elsif /^,$/.token_pat===tok
              if normal_comma_level+1==@parsestack.size and
                 AssignmentRhsContext===@parsestack.last
                #seeing comma here should end implicit rhs started within the param list
                result << AssignmentRhsListEndToken.new(tok.offset)
                @parsestack.pop
              end
              if nextvar and normal_comma_level==@parsestack.size
                localvars[nextvar]=true #now, finally add nextvar back to local vars
                nextvar
              end
            end
         end
         
         @defining_lvar=false
         @parsestack.last.see self,:semi

         assert(@parsestack.size <= old_parsestack_size)
         assert(endingblock[tok] || ErrorToken===tok)

         #hack: force next token to look like start of a
         #new stmt, if the last ignored_tokens
         #call above did not find a newline
         #(just in case the next token parsed
         #happens to call quote_expected? or after_nonid_op)
         result.concat ignored_tokens
#         if  !eof? and nextchar.chr[/[iuw\/<|>+\-*&%?:({]/] and
#             !(NewlineToken===@last_operative_token) and
#             !(/^(end|;)$/===@last_operative_token)
           #result<<EndHeaderToken.new(result.last.offset+result.last.to_s.size)
           set_last_token KeywordToken.new( ';' )
           result<< get1token
#         end
      }

      return result,listend
   end


   #-----------------------------------
   #handle % in ruby code. is it part of fancy quote or a modulo operator?
   def percent(ch)
     if AssignmentContext===@parsestack.last
       @parsestack.pop
       op=true
     end

     if !op and quote_expected?(ch)  ||
       (@last_operative_token===/^(return|next|break)$/ and KeywordToken===@last_operative_token)
         fancy_quote ch
     else
         biop ch
     end
   end

   #-----------------------------------
   #handle * & in ruby code. is unary or binary operator?
   def star_or_amp(ch)
     assert('*&'[ch])
     want_unary=unary_op_expected?(ch) || 
       (@last_operative_token===/^(return|next|break)$/ and KeywordToken===@last_operative_token)
     result=quadriop(ch)
     if want_unary
       #readahead(2)[1..1][/[\s\v#\\]/] or #not needed?
       assert OperatorToken===result
       result.unary=true         #result should distinguish unary+binary *&
       WHSPLF[nextchar.chr] or
         @moretokens << NoWsToken.new(input_position)
       comma_in_lvalue_list?
       if ch=='*'
         @parsestack.last.see self, :splat
       end
     end
     result
   end

   #-----------------------------------
   #handle ? in ruby code. is it part of ?..: or a character literal?
   def char_literal_or_op(ch)
      if colon_quote_expected? ch
         getchar
         NumberToken.new getchar_maybe_escape
      else
         @parsestack.push TernaryContext.new(@linenum)
         KeywordToken.new getchar   #operator
      end
   end

   #-----------------------------------
   def regex_or_div(ch) 
   #space after slash always means / operator, rather than regex start
   #= after slash always means /= operator, rather than regex start
     if AssignmentContext===@parsestack.last
       @parsestack.pop
       op=true
     end

     if !op and after_nonid_op?{ 
          !is_var_name? and WHSPLF[prevchar] and !readahead(2)[%r{^/[\s\v=]}] 
        } || (KeywordToken===@last_token_maybe_implicit and @last_token_maybe_implicit.ident=="(")
       return regex(ch)
     else #/ is operator
       result=getchar
       if eat_next_if(?=)
         result << '='
       end
       return(operator_or_methname_token result)
     end
   end

   #-----------------------------------
   #return true if last tok corresponds to a variable or constant, 
   #false if its for a method, nil for something else
   #we assume it is a valid token with a correctly formed name.
   #...should really be called was_var_name
   def is_var_name?
     (tok=@last_operative_token)

     s=tok.to_s
     case s
     when /[^a-z_0-9]$/i; false
#     when /^[a-z_]/; localvars===s or VARLIKE_KEYWORDS===s
     when /^[A-Z_]/i; VarNameToken===tok
     when /^[@$<]/; true
     else raise "not var or method name: #{s}"
     end   
   end
   
   #-----------------------------------
   def colon_quote_expected?(ch) #yukko hack
     assert ':?'[ch]
     readahead(2)[/^(\?[^#{WHSPLF}]|:[^\s\r\n\t\f\v :])$/o]   or return false

     after_nonid_op? {
       #possible func-call as operator

       not is_var_name? and
         if ch==':'
           not TernaryContext===@parsestack.last
         else
           !readahead(3)[/^\?[a-z0-9_]{2}/i]
         end
     }
   end

   #-----------------------------------
   def symbol_or_op(ch)
      startpos= input_position


      qe= colon_quote_expected?(ch)
      lastchar=prevchar
      eat_next_if(ch[0]) or raise "needed: "+ch

      if nextchar==?( and @enable_macro
        result= OperatorToken.new(':', startpos)
        result.unary=true
        return result
      end

      #handle quoted symbols like  :"foobar",  :"[]"
      qe and return symbol(':')

      #look for another colon; return single : if not found
      unless eat_next_if(?:) 
        #cancel implicit contexts...
        @moretokens.push(*abort_noparens!(':'))
        @moretokens.push tok=KeywordToken.new(':',startpos)
        
        case @parsestack.last
        when TernaryContext: 
          tok.ternary=true
          @parsestack.pop #should be in the context's see handler
        when ExpectDoOrNlContext: #should be in the context's see handler
          @parsestack.pop
          assert @parsestack.last.starter[/^(while|until|for)$/]
          tok.as=";"
        when ExpectThenOrNlContext,WhenParamListContext: 
          #should be in the context's see handler
          @parsestack.pop
          tok.as="then"
        when RescueSMContext:
          tok.as=";"
        else fail ": not expected in #{@parsestack.last.class}->#{@parsestack.last.starter}"
        end
        
        #end ternary context, if any
        @parsestack.last.see self,:colon
        
        return @moretokens.shift
      end
      
      #we definately found a ::

      colon2=KeywordToken.new( '::',startpos)
      lasttok=@last_operative_token
      assert !(String===lasttok)
      if (VarNameToken===lasttok or MethNameToken===lasttok) and
          lasttok===/^[$@a-zA-Z_]/ and !WHSPCHARS[lastchar]
      then
         @moretokens << colon2
         result= NoWsToken.new(startpos)
      else
         result=colon2
      end
      dot_rhs(colon2)
      return result
   end

   #-----------------------------------
   def symbol(notbare,couldbecallsite=!notbare)
     assert !couldbecallsite
     start= input_position
     notbare and start-=1
     klass=(notbare ? SymbolToken : MethNameToken)
     
     #look for operators
     opmatches=readahead(3)[RUBYSYMOPERATORREX]
     result= opmatches ? read(opmatches.size) :
       case nc=nextchar
         when ?" #"
           assert notbare
           open=':"'; close='"'
           double_quote('"')
         when ?' #'
           assert notbare
           open=":'"; close="'"
           single_quote("'")
         when ?` then read(1) #`
         when ?@ then at_identifier.to_s
         when ?$ then dollar_identifier.to_s
         when ?_,?a..?z then identifier_as_string(?:)
         when ?A..?Z then 
           result=identifier_as_string(?:)
           if @last_operative_token==='::' 
             assert klass==MethNameToken
             /[A-Z_0-9]$/i===result and klass=VarNameToken
           end
           result
         else 
           error= "unexpected char starting symbol: #{nc.chr}"
           '_'
       end
     result= lexerror(klass.new(result,start,notbare ?  ':' : ''),error)
     if open
       result.open=open
       result.close=close
     end
     return result
   end

   def merge_assignment_op_in_setter_callsites?
     false
   end
   #-----------------------------------
   def callsite_symbol(tok_to_errify)
     start= input_position
     
     #look for operators
     opmatches=readahead(3)[RUBYSYMOPERATORREX]
     return [opmatches ? read(opmatches.size) :
       case nc=nextchar
         when ?` then read(1) #`
         when ?_,?a..?z,?A..?Z then 
           context=merge_assignment_op_in_setter_callsites? ? ?: : nc
           identifier_as_string(context)
         else 
           set_last_token KeywordToken.new(';')
           lexerror(tok_to_errify,"unexpected char starting callsite symbol: #{nc.chr}, tok=#{tok_to_errify.inspect}")
           nil
       end, start
      ]
   end

   #-----------------------------------
   def here_header
      read(2)=='<<' or raise "parser insanity"

      dash=eat_next_if(?-)
      quote=eat_next_if( /['"`]/)
      if quote
        ender=til_charset(/[#{quote}]/)
        (quote==getchar) or 
          return lexerror(HerePlaceholderToken.new( dash, quote, ender ), "mismatched quotes in here doc")
        quote_real=true
      else
        quote='"'
        ender=til_charset(/[^a-zA-Z0-9_]/)
        ender.length >= 1  or 
          return lexerror(HerePlaceholderToken.new( dash, quote, ender, nil ), "invalid here header")
      end

      res= HerePlaceholderToken.new( dash, quote, ender, quote_real )
if true
      res.open=["<<",dash,quote,ender,quote].to_s
      procrastinated=til_charset(/[\n]/)#+readnl
      unless @base_file
        @base_file=@file
        @file=Sequence::List.new([@file])
        @file.pos=@base_file.pos
      end
      #actually delete procrastinated from input
      @file.delete(input_position_raw-procrastinated.size...input_position_raw) 
      
      nl=readnl or return lexerror(res, "here header without body (at eof)")

      @moretokens<< res
      bodystart=input_position
      @offset_adjust = @min_offset_adjust+procrastinated.size
      #was: @offset_adjust += procrastinated.size
      body=here_body(res)
      res.close=body.close
      @offset_adjust = @min_offset_adjust
      #was: @offset_adjust -= procrastinated.size
      bodysize=input_position-bodystart

      #one or two already read characters are overwritten here,
      #in order to keep offsets correct in the long term
      #(at present, offsets and line numbers between 
      #here header and its body will be wrong. but they should re-sync thereafter.)
      newpos=input_position_raw-nl.size
      #unless procrastinated.empty?
        @file.modify(newpos,nl.size,procrastinated+nl) #vomit procrastinated text back onto input
      #end
      input_position_set newpos

      #line numbers would be wrong within the procrastinated section
      @linenum-=1

      #be nice to get the here body token at the right place in input, too...
      @pending_here_bodies<< body
      @offset_adjust-=bodysize#+nl.size

      return @moretokens.shift
else
      @incomplete_here_tokens.push res

      #hack: normally this should just be in get1token
      #this fixup is necessary because the call the get1token below
      #makes a recursion.
      set_last_token res

      safe_recurse { |a|
         assert(a.object_id==@moretokens.object_id)
         toks=[]
         begin
           #yech. 
           #handle case of here header in a string inclusion, but
           #here body outside it.
           cnt=0
           1.upto @parsestack.size do |i|
             case @parsestack[-i]
               when AssignmentRhsContext,ParamListContextNoParen,TopLevelContext
               else cnt+=1
             end
           end
           if nextchar==?} and cnt==1
             res.bodyclass=OutlinedHereBodyToken
             break
           end
           
           tok=get1token
           assert(a.equal?( @moretokens))
           toks<< tok
           EoiToken===tok and lexerror tok, "here body expected before eof"
         end while res.unsafe_to_use
         assert(a.equal?( @moretokens))
         a[0,0]= toks   #same as a=toks+a, but keeps a's id
      }

      return res

      #the action continues in newline, where
      #the rest of the here token is read after a
      #newline has been seen and res.affix is eventually called
end
   end

   #-----------------------------------
   def lessthan(ch) #match quadriop('<') or here doc or spaceship op
      case readahead(3)
        when /^<<['"`\-a-z0-9_]$/i #'
           if quote_expected?(ch) and not @last_operative_token==='class'
              here_header
           else
              operator_or_methname_token read(2)
           end
        when "<=>" then operator_or_methname_token read(3)
        else quadriop(ch)
      end
   end

   #-----------------------------------
   def escnewline(ch)
      assert ch == '\\'
      
      pos= input_position
      result=getchar
      if nl=readnl
        result+=nl
      else
        error='illegal escape sequence'
      end
      
      #optimization: when thru with regurgitated text from a here document,
      #revert back to original unadorned Sequence instead of staying in the List.
      if @base_file and indices=@file.instance_eval{@start_pos} and 
         (indices[-2]..indices[-1])===@file.pos
        @base_file.pos=@file.pos
        @file=@base_file
        @base_file=nil
        result="\n"
      end
      
      @offset_adjust=@min_offset_adjust
      @moretokens.push( *optional_here_bodies )
      ln=@linenum
      @moretokens.push lexerror(EscNlToken.new(@filename,ln-1,result,input_position-result.size), error),
                       FileAndLineToken.new(@filename,ln,input_position)

      start_of_line_directives

      return @moretokens.shift
   end
  
   #-----------------------------------
   def optional_here_bodies
     result=[]
if true
      #handle here bodies queued up by previous line
      pos=input_position
      while body=@pending_here_bodies.shift
        #body.offset=pos
        result.push EscNlToken.new(@filename,nil,"\n",body.offset-1)
        result.push FileAndLineToken.new(@filename,body.ident.line,body.offset)
        result.push body
        #result.push NoWsToken.new @pending_here_bodies.empty? ? input_position : @pending_here_bodies.first
        #result.push FileAndLineToken.new(@filename,@linenum,pos) #position and line num are off
        body.headtok.line=@linenum-1
      end
else
      #...(we should be more compatible with dos/mac style newlines...)
      while tofill=@incomplete_here_tokens.shift
        result.push(
          here_body(tofill), 
          FileAndLineToken.new(@filename,@linenum,input_position)
        )
        assert(eof?  || "\r\n"[prevchar])
        tofill.line=@linenum-1
      end
end
     return result
   end

   #-----------------------------------
   def here_body(tofill)
         close="\n"
         tofill.string.offset= input_position
         linecount=1 #for terminator
         assert("\n"==prevchar)
         loop {
            assert("\n"==prevchar)

            #here body terminator?
            oldpos= input_position_raw
            if tofill.dash
              close+=til_charset(/[^#{WHSP}]/o)
            end
            break if eof? #this is an error, should be handled better
            if read(tofill.ender.size)==tofill.ender
              crs=til_charset(/[^\r]/)||''
              if nl=readnl
                close+=tofill.ender+crs+nl
                break
              end
            end
            input_position_set oldpos
            
            assert("\n"==prevchar)

            if tofill.quote=="'" 
              line=til_charset(/[\n]/)
              unless nl=readnl
                assert eof?
                break  #this is an error, should be handled better
              end
              line.chomp!("\r")
              line<< "\n"
              assert("\n"==prevchar)
              #line.gsub! "\\\\", "\\"
              tofill.append line
              tofill.string.bs_handler=:squote_heredoc_esc_seq
              linecount+=1
              assert("\n"==line[-1,1])
              assert("\n"==prevchar)
            else

              assert("\n"==prevchar)

              back1char  #-1 to make newline char the next to read
              @linenum-=1
  
              assert( /[\r\n]/===nextchar.chr )

              #retr evrything til next nl
if FASTER_STRING_ESCAPES
              line=all_quote("\r\n", tofill.quote, "\r\n")
else
              line=all_quote(INET_NL_REX, tofill.quote, INET_NL_REX)
end
              linecount+=1
              #(you didn't know all_quote could take a regex, did you?)
  
              assert("\n"==prevchar)

              #get rid of fals that otherwise appear to be in the middle of
              #a string (and are emitted out of order)
              fal=@moretokens.pop
              assert FileAndLineToken===fal || fal.nil?
  
              assert line.bs_handler
              tofill.string.bs_handler||=line.bs_handler

              tofill.append_token line
              tofill.string.elems<<'' unless String===tofill.string.elems.last

              assert("\n"==prevchar)

              back1char
              @linenum-=1
              assert("\r\n"[nextchar.chr])
              tofill.append readnl

              assert("\n"==prevchar)
            end

            assert("\n"==prevchar)
         }
         

         str=tofill.string
         str.bs_handler||=:dquote_esc_seq if str.elems.size==1 and str.elems.first==''
         tofill.unsafe_to_use=false
         assert str.bs_handler
           #?? or tofill.string.elems==[]
	
          
        tofill.string.instance_eval{@char="`"} if tofill.quote=="`"
        #special cased, but I think that's all that's necessary...

        result=tofill.bodyclass.new(tofill,linecount)
        result.open=str.open=""
        tofill.close=close
        result.close=str.close=close[1..-1]
        result.offset=str.offset
        assert str.open
        assert str.close
        return result
   end

   #-----------------------------------
   def newline(ch)
      assert("\r\n"[nextchar.chr])

      #ordinary newline handling (possibly implicitly escaped)
      assert("\r\n"[nextchar.chr])
                   assert !@parsestack.empty?
      assert @moretokens.empty?

      pre=FileAndLineToken.new(@filename,@linenum+1,input_position)
      pre.allow_ooo_offset=true

      if NewlineToken===@last_operative_token or #hack
         (KeywordToken===@last_operative_token and 
          @last_operative_token.ident=="rescue" and
          !@last_operative_token.infix?)  or 
         #/^(;|begin|do|#{INNERBOUNDINGWORDS})$/ or #hack
         !after_nonid_op?{false}
      then   #hack-o-rama: probly cases left out above
        @offset_adjust=@min_offset_adjust
        a= abort_noparens!
        case @parsestack.last  #these should be in the see:semi handler
          when ExpectDoOrNlContext: @parsestack.pop
          when ExpectThenOrNlContext: @parsestack.pop        
        end
        assert !@parsestack.empty?
        @parsestack.last.see self,:semi

        a << super(ch)
        @moretokens.replace a+@moretokens
      else
        @offset_adjust=@min_offset_adjust
        offset= input_position
        nl=readnl
        @moretokens.push EscNlToken.new(@filename,@linenum-1,nl,offset),
           FileAndLineToken.new(@filename,@linenum,input_position)
      end

      #optimization: when thru with regurgitated text from a here document,
      #revert back to original unadorned Sequence instead of staying in the list.
      if @base_file and indices=@file.instance_eval{@start_pos} and
         (indices[-2]..indices[-1])===@file.pos and Sequence::SubSeq===@file.list.last
        @base_file.pos=@file.pos
        @file=@base_file
        @base_file=nil
      end

      fal=@moretokens.last
      assert FileAndLineToken===fal

      @offset_adjust=@min_offset_adjust

      @moretokens.unshift(*optional_here_bodies)
      result=@moretokens.shift

      #adjust line count in fal to account for newlines in here bodys
      i=@moretokens.size-1
      while(i>=0)
        #assert FileAndLineToken===@moretokens[i]
        i-=1 if FileAndLineToken===@moretokens[i]
        break unless HereBodyToken===@moretokens[i]
        pre_fal=true
        fal.line-=@moretokens[i].linecount

        i-=1
      end

      if pre_fal
        @moretokens.unshift result
        pre.offset=result.offset
        result=pre
      end
      start_of_line_directives

      return result
   end

   #-----------------------------------
   EQBEGIN=%r/^=begin[ \t\v\r\n\f]$/
   EQBEGINLENGTH=7
   EQEND='=end'
   EQENDLENGTH=4
   ENDMARKER=/^__END__[\r\n]?\Z/
   ENDMARKERLENGTH=8
   def start_of_line_directives
      #handle =begin...=end (at start of a line)
      while EQBEGIN===readahead(EQBEGINLENGTH)
         startpos= input_position
         more= read(EQBEGINLENGTH-1)   #get =begin

         begin
           eof? and raise "eof before =end"
           more<< til_charset(/[\r\n]/)
           eof? and raise "eof before =end"
           more<< readnl
         end until readahead(EQENDLENGTH)==EQEND

         #read rest of line after =end
         more << til_charset(/[\r\n]/)  
         assert((eof? or ?\r===nextchar or ?\n===nextchar))
         assert !(/[\r\n]/===more[-1,1])
         more<< readnl unless eof?

#         newls= more.scan(/\r\n?|\n\r?/)
#         @linenum+= newls.size

         #inject the fresh comment into future token results
         @moretokens.push IgnoreToken.new(more,startpos),
                          FileAndLineToken.new(@filename,@linenum,input_position)
      end

      #handle __END__
      if ENDMARKER===readahead(ENDMARKERLENGTH)
         assert !(ImplicitContext===@parsestack.last)
         @moretokens.unshift endoffile_detected(read(ENDMARKERLENGTH))
#         input_position_set @file.size
      end
   end



  #-----------------------------------
  #used to resolve the ambiguity of
  # unary ops (+, -, *, &, ~ !) in ruby
  #returns whether current token is to be the start of a literal
  IDBEGINCHAR=/^[a-zA-Z_$@]/
  def unary_op_expected?(ch) #yukko hack
    '*&='[readahead(2)[1..1]] and return false

    return true if KeywordToken===@last_operative_token and @last_operative_token==='for'
 
    after_nonid_op? {
      #possible func-call as operator

      not is_var_name? and
        WHSPLF[prevchar] and !WHSPLF[readahead(2)[1..1]]
    }
  end

   #-----------------------------------
   #used to resolve the ambiguity of
   # <<, %, ? in ruby
   #returns whether current token is to be the start of a literal
   def quote_expected?(ch) #yukko hack
     case ch[0]
          when ?? then readahead(2)[/^\?[#{WHSPLF}]$/o] #not needed?
          when ?% then readahead(3)[/^%([a-pt-vyzA-PR-VX-Z]|[QqrswWx][a-zA-Z0-9])/]
          when ?< then !readahead(4)[/^<<-?['"`a-z0-9_]/i]
          else raise 'unexpected ch (#{ch}) in quote_expected?'
     #     when ?+,?-,?&,?*,?~,?! then '*&='[readahead(2)[1..1]]
     end and return false

     after_nonid_op? {
       #possible func-call as operator

       not is_var_name? and
         WHSPLF[prevchar] and not WHSPLF[readahead(2)[1..1]]
     }
   end

   #-----------------------------------
   #returns false if last token was an value, true if it was an operator.
   #returns what block yields if last token was a method name.
   #used to resolve the ambiguity of
   # <<, %, /, ?, :, and newline (among others) in ruby
   def after_nonid_op?

    #this is how it should be, I think, and then no handlers for methnametoken and FUNCLIKE_KEYWORDS are needed
#      if ImplicitParamListStartToken===@last_token_including_implicit
#        huh return true
#      end
      case @last_operative_token
         when VarNameToken , MethNameToken, FUNCLIKE_KEYWORDS.token_pat 
         #VarNameToken should really be left out of this case... 
         #should be in next branch instread
         #callers all check for last token being not a variable if they pass anything
         #but {false} in the block 
         #(hmmm... some now have true or other non-varname checks in them... could these be bugs?)
            return yield
         when StringToken, SymbolToken, NumberToken, HerePlaceholderToken,
              %r{^(
                end|self|true|false|nil|  
                __FILE__|__LINE__|[\})\]]
              )$}x.token_pat
            #dunno about def/undef
            #maybe class/module shouldn't he here either?  
            #for is also in NewlineToken branch, below.
            #what about rescue?
            return false
         when /^(#{RUBYOPERATORREX}|#{INNERBOUNDINGWORDS}|do)$/o.token_pat
            #regexs above must match whole string
            #assert(@last_operative_token==$&) #disabled 'cause $& is now always nil :(
            return true if OperatorToken===@last_operative_token || KeywordToken===@last_operative_token
         when NewlineToken, nil,   #nil means we're still at beginning of file
              /^([({\[]|or|not|and|if|unless|then|elsif|else|class|module|def|
                 while|until|begin|for|in|case|when|ensure|defined\?)$
              /x.token_pat
            return true
         when KeywordToken
            return true if /^(alias|undef)$/===@last_operative_token.ident  #is this ever actually true???
         when IgnoreToken
            raise "last_operative_token shouldn't be ignoreable"
      end
      raise "after_nonid_op? after #{@last_operative_token}:#{@last_operative_token.class} -- now what"
   end




   #-----------------------------------
   #returns the last context on @parsestack which isn't an ImplicitContext
   def last_context_not_implicit
     @parsestack.reverse_each{|ctx|
       return ctx unless ImplicitContext===ctx
     }
     fail
   end

   #-----------------------------------
   #a | has been seen. is it an operator? or a goalpost?
   #(goalpost == delimiter of block param list)
   #if it is a goalpost, end the BlockParamListLhsContext on
   #the context stack, as well as any implicit contexts on top of it.
   def conjunction_or_goalpost(ch)
     result=quadriop(ch)
     if result===/^|$/ and BlockParamListLhsContext===last_context_not_implicit 
       @moretokens.push( *abort_noparens!("|"))
       assert(BlockParamListLhsContext===@parsestack.last)
       @parsestack.pop
       @moretokens.push KeywordToken.new("|", input_position-1)
       result=@moretokens.shift
     end
     result
   end
   
   #-----------------------------------
   def quadriop(ch) #match /&&?=?/ (&, &&, &=, or &&=)
      assert(%w[& * | < >].include?(ch))
      result=getchar + (eat_next_if(ch)or'')
      if eat_next_if(?=)
         result << ?=
      end
      return operator_or_methname_token(result)
   end


    #-----------------------------------
    def caret(ch) #match /^=?/ (^ or ^=) (maybe unary ^ too)
      if @enable_macro and (@last_token_maybe_implicit and
         @last_token_maybe_implicit.ident=='(') || unary_op_expected?(ch)
           result=OperatorToken.new(read(1),input_position)
           result.unary=true
           result
      else
           biop ch
      end
    end

    #-----------------------------------
    def biop(ch) #match /%=?/ (% or %=)
      assert(ch[/^[%^]$/])
      oldpos=input_position
      result=getchar
      if eat_next_if(?=)
         result << ?=
      end
      result= operator_or_methname_token( result)
      result.offset=oldpos
      return result
   end

   #-----------------------------------
   def tilde(ch) #match ~
      assert(ch=='~')
      result=getchar
#      eat_next_if(?=) ?   #ack, spppft, I'm always getting this backwards
#         result <<?= :
         WHSPLF[nextchar.chr] ||
           @moretokens << NoWsToken.new(input_position)
      #why is the NoWsToken necessary at this point?    
      result=operator_or_methname_token result
      result.unary=true         #result should distinguish unary ~
      result
   end

   #-----------------------------------
   def want_op_name
      KeywordToken===@last_operative_token and
         @last_operative_token===/^(alias|(un)?def|\.|::)$/
   end

   #-----------------------------------
   #match /[+\-]=?/ (+ or +=)
   #could be beginning of number, too
   #fixme: handle +@ and -@ here as well... (currently, this is done in symbol()?)
   def plusminus(ch)
      assert(/^[+\-]$/===ch)
      if unary_op_expected?(ch) or 
         KeywordToken===@last_operative_token && 
         /^(return|break|next)$/===@last_operative_token.ident
        if (?0..?9)===readahead(2)[1]
          return number(ch)
        else #unary operator
          result=getchar
          WHSPLF[nextchar.chr] or
            @moretokens << NoWsToken.new(input_position)
          result=(operator_or_methname_token result)
          result.unary=true
        end
      else #binary operator
         assert(! want_op_name)
         result=getchar
         if eat_next_if(?=)
            result << ?=
         end
         result=(operator_or_methname_token result)
      end
      return result
   end

   #-----------------------------------
   def equals(ch) #match /=(>|~|==?)?/ (= or == or =~ or === or =>)
      offset= input_position
      str=getchar
      assert str=='='
      c=(eat_next_if(/[~=>]/)or'')
      str << c
      result= operator_or_methname_token( str,offset)
      case c
      when '=': #===,==
        str<< (eat_next_if(?=)or'')
      
      when '>': #=>
        unless ParamListContextNoParen===@parsestack.last
          @moretokens.unshift result
          @moretokens.unshift( *abort_noparens!("=>"))
          result=@moretokens.shift
        end
        @parsestack.last.see self,:arrow
      when '': #plain assignment: record local variable definitions
        last_context_not_implicit.lhs=false
        @moretokens.push( *ignored_tokens(true).map{|x| 
          NewlineToken===x ? EscNlToken.new(@filename,@linenum,x.ident,x.offset) : x 
        } )
        @parsestack.push AssignmentRhsContext.new(@linenum)
        if eat_next_if ?* 
          tok=OperatorToken.new('*', input_position-1)
          tok.unary=true
          @moretokens.push tok
          WHSPLF[nextchar.chr] or
            @moretokens << NoWsToken.new(input_position)
          comma_in_lvalue_list? #is this needed?
        end
        @moretokens.push AssignmentRhsListStartToken.new( input_position)
      end
      return result
   end

   #-----------------------------------
   def exclam(ch) #match /![~=]?/ (! or != or !~)
      assert nextchar==?!
      result=getchar
      k=eat_next_if(/[~=]/)
      if k
        result+=k
      elsif eof?: #do nothing
      else
        WHSPLF[nextchar.chr] or
          @moretokens << NoWsToken.new(input_position)
      end
      return KeywordToken.new(result, input_position-result.size)
      #result should distinguish unary !
   end


   #-----------------------------------
   def dot(ch)
      str=''
      eat_next_if(?.) or raise "lexer confusion"

      #three lumps of sugar or two?
      eat_next_if(?.) and
         return KeywordToken.new(eat_next_if(?.)? "..." : "..")

      #else saw just single .
      #match a valid ruby id after the dot
      result= KeywordToken.new( ".")
      dot_rhs(result)
      return result
   end
   #-----------------------------------
   def dot_rhs(prevtok)
      safe_recurse { |a|
         set_last_token prevtok
         aa= ignored_tokens
         was=after_nonid_op?{true}
         tok,pos=callsite_symbol(prevtok)
         tok and aa.push(*var_or_meth_name(tok,prevtok,pos,was)) 
         a.unshift(*aa)
      }     
   end

  #-----------------------------------
  def back_quote(ch=nil)
    if @last_operative_token===/^(def|::|\.)$/
      oldpos= input_position
      MethNameToken.new(eat_next_if(?`), oldpos) #`
    else
      double_quote(ch)
    end
  end

if false
   #-----------------------------------
   def comment(str)
     result=""
     #loop{
       result<< super(nil).to_s

       if /^\#.*\#$/===result #if comment was ended by a crunch

         #that's not a legal comment end in ruby, so just keep reading
         assert(result.to_s[-1]==?#)
         result.chomp! '#'

         #back up one char in input so that the
         #super will see that # on the next go round.
         #this hack makes the ruma comment lexer work with ruby too.
         back1char

         assert nextchar==?#
       #else break #not a crunch... just exit
       end
     #}

     return IgnoreToken.new(result)
   end
end
   #-----------------------------------
   def open_brace(ch)
      assert((ch!='[' or !want_op_name))
      assert(@moretokens.empty?)
      lastchar=prevchar
      ch=eat_next_if(/[({\[]/)or raise "lexer confusion"
      tokch=KeywordToken.new(ch, input_position-1)
      

      #maybe emitting of NoWsToken can be moved into var_or_meth_name ??
      case tokch.ident
      when '['
        # in contexts expecting an (operator) method name, we 
        #       would want to match [] or []= at this point
        #but control never comes this way in those cases... goes 
        #to custom parsers for alias, undef, and def in #parse_keywords
        tokch.set_infix! unless after_nonid_op?{WHSPLF[lastchar]}
        @parsestack.push ListImmedContext.new(ch,@linenum)
        lasttok=last_operative_token
        #could be: lasttok===/^[a-z_]/i
        if (VarNameToken===lasttok or ImplicitParamListEndToken===lasttok or MethNameToken===lasttok) and !WHSPCHARS[lastchar]
               @moretokens << (tokch)
               tokch= NoWsToken.new(input_position-1)
        end
      when '('
        lasttok=last_token_maybe_implicit #last_operative_token
        #could be: lasttok===/^[a-z_]/i
        if (VarNameToken===lasttok or MethNameToken===lasttok or
            lasttok===FUNCLIKE_KEYWORDS)
          unless WHSPCHARS[lastchar]
               @moretokens << tokch
               tokch= NoWsToken.new(input_position-1)
          end
          @parsestack.push ParamListContext.new(@linenum)
        else
          @parsestack.push ParenContext.new(@linenum)
        end

      when '{'
      #check if we are in a hash literal or string inclusion (#{}),
      #in which case below would be bad.
      if after_nonid_op?{false} or @last_operative_token.has_no_block?
        @parsestack.push ListImmedContext.new(ch,@linenum) #that is, a hash
      else
        #abort_noparens!
        tokch.set_infix!
        tokch.as="do"
#=begin not needed now, i think
        # 'need to find matching callsite context and end it if implicit'
        lasttok=last_operative_token
        if !(lasttok===')' and lasttok.callsite?) #or ParamListContextNoParen===parsestack.last
          @moretokens.push( *(abort_1_noparen!(1).push tokch) )
          tokch=@moretokens.shift
        end
#=end

        localvars.start_block
        @parsestack.push BlockContext.new(@linenum)
        block_param_list_lookahead
      end
      end
      return (tokch)
   end

   #-----------------------------------
   def close_brace(ch)
      ch==eat_next_if(/[)}\]]/) or raise "lexer confusion"
      @moretokens.concat abort_noparens!(ch)
      @parsestack.last.see self,:semi #hack
      @moretokens<< kw=KeywordToken.new( ch, input_position-1)
      if @parsestack.empty? 
        lexerror kw,"unmatched brace: #{ch}"
        return @moretokens.shift
      end
      ctx=@parsestack.pop
      origch,line=ctx.starter,ctx.linenum
      if ch!=PAIRS[origch]
        #kw.extend MismatchedBrace
        lexerror kw,"mismatched braces: #{origch}#{ch}\n" +
                 "matching brace location", @filename, line
      end
      localvars.end_block if BlockContext===ctx
      @moretokens.last.as="end" if BlockContext===ctx or BeginEndContext===ctx
      if ParamListContext==ctx.class
        assert ch==')'
        kw.set_callsite! #not needed?
      end
      return @moretokens.shift
   end

   #-----------------------------------
   def eof(ch=nil)
     #this must be the very last character...
     oldpos= input_position
     assert(/\A[\x0\x4\x1a]\Z/===nextchar.chr)

     result=@file.read!
#     result= "\0#{ignored_tokens(true).delete_if{|t|FileAndLineToken===t}}"

#     eof? or
#        lexerror result,'nul character is not at the end of file'
#     input_position_set @file.size
     return(endoffile_detected result)
   end

   #-----------------------------------
   def endoffile_detected(s='')
     @moretokens.push( *(abort_noparens!.push super(s)))
     if @progress_thread
       @progress_thread.kill
       @progress_thread=nil
     end
     result= @moretokens.shift
     balanced_braces? or (lexerror result,"unbalanced braces at eof. parsestack=#{@parsestack.inspect}")
     result
   end

  #-----------------------------------
  def single_char_token(ch)
    KeywordToken.new super(ch), input_position-1
  end

  #-----------------------------------
  def comma(ch)
    @moretokens.push token=single_char_token(ch)

    #if assignment rhs seen inside method param list, when param list, array or hash literal,
    #       rescue where comma is expected, or method def param list
    #          then end the assignment rhs now
       #+[OBS,ParamListContext|ParamListContextNoParen|WhenParamListContext|ListImmedContext|
       #      (RescueSMContext&-{:state=>:rescue})|(DefContext&-{:in_body=>FalseClass|nil}),
       #  AssignmentRhsContext
       #]===@parsestack
    if AssignmentRhsContext===@parsestack[-1] and
       ParamListContext===@parsestack[-2] || 
       ParamListContextNoParen===@parsestack[-2] ||
       WhenParamListContext===@parsestack[-2] ||
       ListImmedContext===@parsestack[-2] ||
       (RescueSMContext===@parsestack[-2] && @parsestack[-2].state==:rescue) ||
       (DefContext===@parsestack[-2] && !@parsestack[-2].in_body)
         @parsestack.pop
         @moretokens.unshift AssignmentRhsListEndToken.new(input_position)
    end
    token.comma_type=
    case @parsestack[-1]
    when AssignmentRhsContext; :rhs
    when ParamListContext,ParamListContextNoParen; :call
    when ListImmedContext; :array
    else
      :lhs if comma_in_lvalue_list? 
    end
    @parsestack.last.see self,:comma
    return @moretokens.shift
  end
  
  #-----------------------------------
  def semicolon(ch)
    assert @moretokens.empty?
    @moretokens.push(*abort_noparens!)
    @parsestack.last.see self,:semi
    case @parsestack.last #should be in context's see:semi handler
    when ExpectThenOrNlContext
      @parsestack.pop
    when ExpectDoOrNlContext
      @parsestack.pop
      assert @parsestack.last.starter[/^(while|until|for)$/]
    end
    @moretokens.push single_char_token(ch)
    return @moretokens.shift
  end

  #-----------------------------------
  def operator_or_methname_token(s,offset=nil)
    assert RUBYOPERATORREX===s
    if RUBYNONSYMOPERATORREX===s
      KeywordToken
    elsif want_op_name
      MethNameToken
    else 
      OperatorToken
    end.new(s,offset)
  end

  #-----------------------------------
  #tokenify_results_of  :identifier
  save_offsets_in(*CHARMAPPINGS.values.uniq-[
    :symbol_or_op,:open_brace,:whitespace,:exclam,:backquote,:caret
  ])
  #save_offsets_in :symbol

end


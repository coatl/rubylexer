=begin
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

if defined? RubyLexer #sigh
  Object.send :remove_const, :RubyLexer
end

require "assert"
#require "charhandler"
#require "term"
#require "rubycode"
#require "io.each_til_charset"
begin
  require 'rubygems'
rescue LoadError=>e
  raise unless /rubygems/===e.message
  #hope we don't need it
end
begin
  #require 'sequence'
  require 'sequence/indexed'
  require 'sequence/file'
  require 'sequence/list'
rescue LoadError
  trydir=File.expand_path File.dirname(__FILE__)+"/../../../sequence/lib"
  raise if $:.include? trydir
  warn "hacking $LOAD_PATH to find latest sequence"
  $:<<trydir
  retry
end
#-----------------------------------
assert !defined? ::RubyLexer
class RubyLexer
  FASTER_STRING_ESCAPES=true
  warn "FASTER_STRING_ESCAPES is off" unless FASTER_STRING_ESCAPES
  AUTO_UNESCAPE_STRINGS=false
   WHSP=" \t\r\v\f"
   WHSPLF=WHSP+"\n"
   #maybe \r should be in WHSPLF instead

   LEGALCHARS=/[!-~#{WHSPLF}\x80-\xFF]/

   PAIRS={ '{'=>'}', '['=>']', '('=>')', '<'=>'>'}

   attr_reader :linenum,:last_operative_token,:original_file,:filename
   attr_accessor :file #hack

   #-----------------------------------
   def initialize(filename, file, line, offset_adjust=0)
      @filename=filename

#      String===file && file=IOext::FakeFile.new(file)
      file.binmode if File===file
      @original_file=file
      @file=file.to_sequence
      @file.pos=@original_file.pos if @original_file.respond_to? :pos
      @linenum=line
      @toptable=nil   #descendants must fill this out
      @min_offset_adjust=@offset_adjust=offset_adjust
      @moretokens=[ RubyLexer::FileAndLineToken.new(@filename, @linenum, input_position) ]
      @endsets={}
   end
   alias rulexer_initialize initialize

   #-----------------------------------
   def endoffile_detected s=''
     EoiToken.new(s,@original_file, input_position-s.size,@linenum)
   end
   alias rulexer_endoffile_detected endoffile_detected

   #-----------------------------------
   def get1token
      @moretokens.empty? or return result=@moretokens.shift

      if eof?
         #@moretokens<<nil
         return result=endoffile_detected()
      end

      return result=@toptable.go( nextchar )
   ensure
      #hacky: result.endline should already be set
      result.endline||=@linenum if result
   end
   alias rulexer_get1token get1token

   #-----------------------------------
   def no_more?
     @moretokens.each{|t| FileAndLineToken===t or return false }
     return true
   end

   #-----------------------------------
   def each
     begin yield tok = get1token
     end until tok.is_a? EoiToken
   end

   #-----------------------------------
#   def offset_adjust; 0 end

   #-----------------------------------
#   def offset_adjust_set! offset_adjust
#     @offset_adjust=offset_adjust
#   end

   include Enumerable

private
   #-----------------------------------
   def lexerror_errortoken(tok,str,file=@filename,line=@linenum)
      str or return tok
      tok.extend(ErrorToken).error=str
      tok
   end

   #-----------------------------------
   def lexerror_exception(tok,str,file=@filename,line=@linenum)
      str or return tok
      raise [file,line,'  '+str].join(':')
   end

   #-----------------------------------
   alias lexerror lexerror_errortoken

   #-----------------------------------
   def handler_loop(handler)
      @file.each_byte {|b|   handler.go(b) or break   }
   end

   #-----------------------------------
   def regex(ch=nil)
      result= double_quote("/")
      if false and @rubyversion>=1.9
        named_brs=[]
        if result.elems.size==1 and String===result.elems.first
            elem=result.elems.first
            index=0
            while index=elem.index(/(#{EVEN_BS_S})( \(\?[<'] | \(\?\# | \[ )/xo,index)
              index+=$1.size
              case $2
              when "(?<"
                index=elem.index(/\G...(#{LCLETTER}#{LETTER_DIGIT}+)>/o,index)
                break lexerror(result, "malformed named backreference") unless index
                index+=$&.size
                named_brs<<$1
              when "(?'"
                index=elem.index(/\G...(#{LCLETTER}#{LETTER_DIGIT}+)'/o,index)
                break lexerror(result, "malformed named backreference") unless index
                index+=$&.size
                named_brs<<$1
              when "(?#"
                index+=3
                index=elem.index(/#{EVEN_BS_S}\)/o,index)
                break lexerror(result, "unterminated regexp comment") unless index
                index+=$&.size
              when "["
                index+=1
                paren_ctr=1
                loop do
                  index=elem.index(/#{EVEN_BS_S}(&&\[\^|\])/o,index)
                  break lexerror(result, "unterminated character class") unless index
                  index+=$&.size
                  if $1==']'
                    paren_ctr-=1
                    break if paren_ctr==0 
                  else 
                    paren_ctr+=1
                  end
                end
                break unless index
                
              end
            end
        end
        result.lvars= named_brs unless named_brs.empty?
      end
      result.open=result.close="/"
      result.line=@linenum
      return result
   end

   #-----------------------------------
   def single_char_token(str)  getchar   end
   alias rulexer_single_char_token single_char_token

   #-----------------------------------
   def illegal_char(ch)
     pos= input_position
     LEGALCHARS===ch and return( lexerror WsToken.new(getchar,pos), "legal (?!) bad char (code: #{ch[0]})" )
     lexerror WsToken.new(til_charset(LEGALCHARS),pos), "bad char (code: #{ch[0]})"   
   end

   #-----------------------------------
   def fancy_quote (ch)
      assert ch=='%'
      oldpos= input_position
      eat_next_if(ch) or raise "fancy_quote, no "+ch
      strlex=:double_quote
      open="%"

      ch=getchar
      open+=ch
      #ch.tr!('qwQWrx','"["{/`')
      type=case ch
         when 'q' then strlex=:single_quote; "'"
         when 'w' then "[" #word array
         when 'Q' then '"' #regular string
         when 'W' then '{' #dquotish word array
         when 'r' then '/' #regex
         when 'x' then '`' #exec it
         when 's' then strlex=:single_quote; "'" #symbol
         #other letters, nums are illegal here
         when /^#{LCLETTER().gsub('_','')}$/o
            error= "unrecognized %string type: "+ch; '"'
         when ''
            result= lexerror( assign_encoding!(StringToken.new('', oldpos)), "unexpected eof in %string")
            result.line=@linenum
            return result

         else open.chop!; back1char; '"' #no letter means string too
      end

if FASTER_STRING_ESCAPES
      beg= readahead(2)=="\r\n" ? "\r\n" : nextchar.chr
      assert( /[\r\n]/===nextchar.chr ) if beg=="\r\n"
else      
      beg=nextchar.chr
      if /^[\r\n]$/===beg  then 
           beg=INET_NL_REX
      end
end
      result=send(strlex, beg, type, close=(PAIRS[beg] or beg))
      case ch
      when /^[Wwr]$/
        str=result
        result.open=str.open; result.close=str.close
        result.line=@linenum
      when 's'
        result.open=open+beg
        result.close=close
        result=SymbolToken.new result,nil,"%s"
      end
      result.open=open+beg
      result.close=close
      result.offset=oldpos
      return lexerror(result,error)
   end

   #-----------------------------------
   def double_quote(nester, type=nester, delimiter=nester)
      result=all_quote(nester,type,delimiter)
      result.open=nester
      result.close=delimiter
      return result
   end

   #-----------------------------------
   def single_quote(nester, type=nester, delimiter=nester)
     result=all_quote nester, type, delimiter
#     result.elems.first.gsub! /\\\\/, '\\'
     result.open=result.close="'"
     return result
   end

   #-----------------------------------
   def assign_encoding! str
     str
   end

   #-----------------------------------
   INTERIOR_REX_CACHE={}
   EVEN_BS_S=/
     (?:\G|
      [^\\c-]|
      (?:\G|[^\\])(?:c|[CM]-)|
      (?:\G|[^CM])-
     )
     (?:\\(?:c|[CM]-)?){2}*
   /x
   ILLEGAL_ESCAPED=/#{EVEN_BS_S}(\\([CM][^-]|x[^a-fA-F0-9]))/o #whaddaya do with this?
   def all_quote(nester, type, delimiter, bs_handler=nil)
if FASTER_STRING_ESCAPES
      #string must start with nester
      if nester=="\r\n" #treat dos nl like unix
        nester=delimiter="\n"
        readnl
      else
        eat_next_if(nester[0])
      end or return nil
      special_char= nester.dup
      special_char<< (delimiter) if nester!=delimiter

      if "'["[type]
        single_quotish=true
        special=/\\./m
      else
        crunch=/\#(?=[^{$@])/
        escaped=/\\(?>[^xcCM0-7]|(?>c|[CM].)(?>[^\\]|(?=\\))|(?>x.[0-9a-fA-F]?)|(?>[0-7]{1,3}))/m
        special=
          case delimiter
          when '\\'; crunch
          when '#'; escaped
          else /#{escaped}|#{crunch}/o
          end
        special_char<< maybe_crunch="#"
      end
      normal="[^#{Regexp.quote '\\'+special_char}]"
      interior=INTERIOR_REX_CACHE[special_char]||=/(?>#{normal}*)(?>((?>#{special}+)(?>#{normal}*))*)/

      #backslash is just scanned thru, not interpreted
      #... that will change token format
      #, which will make lots of downstream headaches.

      str=StringToken.new type
      str.bs_handler ||= case type
        when '/' then :regex_esc_seq
        when '{' then Wquote_handler_name() #@rubyversion>=1.9 ? :Wquote19_esc_seq : :Wquote_esc_seq
        when '"','`',':' then dquote_handler_name #@rubyversion>=1.9 ? :dquote19_esc_seq : :dquote_esc_seq
        when "'"     then :squote_esc_seq
        when "["     then :wquote_esc_seq
        else raise "unknown quote type: #{type}"
      end

      str.startline=old_linenum=@linenum
      nestlevel=1
      loop{ 
         str.append(@file.scan( interior ))
         #scan could stop at any character if at the end of its buffer.
         b=getchar
         case b
            when delimiter
               assert nestlevel>0
               if (nestlevel-=1)==0

                  
                  case str.elems.last
                  #if last str data fragment was empty and
                  #followed an inclusion, delete it
                  #unless there was an escnl between inclusion and string end
                  when '' 
                    str.elems.size>1 and
                    if /\\\r?\n(.|\r?\n)\Z/===@file.readbehind(5)
                      #do nothing
                    else
                      str.elems.pop
                    end
                  when /\r\Z/      #if delim is \n, trailing (literal) \r is chopped
                    str.elems.last.chomp! "\r" if delimiter=="\n"
                  end

                  str.modifiers=til_charset(/[^eioumnsx]/) if '/'==type
            
                  nlcount=0
                  str.elems.each{|frag| 
                    next unless String===frag
                    #dos nls turn into unix nls in string literals
                    nlcount+=frag.count("\n")
                    frag.gsub!(/\r\n/, "\n")
                  }

                  nlcount+=1 if delimiter=="\n"
                  str.line=@linenum+=nlcount
                  if nlcount>0
                    #emit eol marker later if line has changed
                    @moretokens << FileAndLineToken.new(
                      @filename,@linenum,input_position
                    )
                    @pending_here_bodies.each{|body|
                      body.allow_ooo_offset=true
                    } unless delimiter=="\n"
                  end


                  str.open=nester
                  str.close=delimiter
                  return str
               end
               assert nestlevel>0
            when nester
               #this branch ignored if nester==delimiter
               assert(nester!=delimiter)
               nestlevel+=1
            when nil then raise "nil char from each_byte?" #never happens
            when maybe_crunch
               nc=nextchar.chr
               nc[/^[{@$]$/] and b=ruby_code(nc)
            when "\\"
               back1char
               next
            when ""  #eof
               lexerror str, "unterminated #{delimiter}-string at eof"
               break               
         end


         unless ("['"[type])
           @@ILLEGAL_CRUNCH||=/
             #{EVEN_BS_S}(?:
               \#@(?:(?!#{LETTER()})|[^@]) |
               \#$(?:(?!#{LETTER_DIGIT()})|[^\-!@&+`'=~\/\\,.;<>*"$?:;])
             )
           /ox #and this?

           #shouldn't tolerate ILLEGAL_ESCAPED in str (unless single quotish)....
           lexerror str, "illegal escape sequence" if /#{@@ILLEGAL_CRUNCH}|#{ILLEGAL_ESCAPED}/o===b 
         end

         str.append b
      }

      assert eof?
      str.line=@linenum
      str
else


      endset="\r\n\\\\"

      #string must start with nester
      if nester==INET_NL_REX
        readnl
      else
        endset<< "\\"+nester
        endset<< "\\"+delimiter if nester!=delimiter
        eat_next_if(nester[0])
      end or return nil

      bs_handler ||= case type
        when '/' then :regex_esc_seq
        when '{' then Wquote_handler_name #@rubyversion>=1.9 ? :Wquote19_esc_seq : :Wquote_esc_seq
        when '"','`',':' then dquote_handler_name #@rubyversion>=1.9 ? :dquote19_esc_seq : :dquote_esc_seq
        when "'"     then :squote_esc_seq
        when "["     then :wquote_esc_seq
        else raise "unknown quote type: #{type}"
      end

      str=StringToken.new type
      old_linenum=@linenum
      nestlevel=1
      endset<<maybe_crunch="#" unless "'["[type]
      endset=
        @endsets[endset] ||= /[#{endset}]/
      false&& last_escnl_elem_idx=nil
      loop{ 
         str.append(til_charset( endset ))
         b=getchar
         if /^[\r\n]$/===b
           back1char
           b=readnl
         end
         case b
            when delimiter
               assert nestlevel>0
               if (nestlevel-=1)==0

                  #if last str data fragment was empty and
                  #followed an inclusion, delete it
                  #unless there was an escnl between inclusion and string end
                  if str.elems.last=='' and str.elems.size>1
                    if /\\\r?\n(.|\r?\n)\Z/===@file.readbehind(5)
                      #do nothing
                    else
                      str.elems.pop
                    end
                  end

                  str.modifiers=til_charset(/[^eioumnsx]/) if '/'==type
                  str.line=@linenum
                  if @linenum != old_linenum
                    #emit eol marker later if line has changed
                    @moretokens << FileAndLineToken.new(
                      @filename,@linenum,input_position
                    )
                    @pending_here_bodies.each{|body|
                      body.allow_ooo_offset=true
                    } unless nester==INET_NL_REX
                  end
                  return str
               end
               assert nestlevel>0
            when nester
               #this branch ignored if nester==delimiter
               assert(nester!=delimiter)
               nestlevel+=1
            when "\\"
            begin
               b= send(bs_handler,'\\',nester,delimiter)
            rescue e
               lexerror str, e.message
            end
            when nil then raise "nil char from each_byte?" #never happens
            when maybe_crunch
               nc=nextchar.chr
               nc[/^[{@$]$/] and b=ruby_code(nc)
            when ""  #eof
               lexerror str, "unterminated #{delimiter}-string at eof"
               break               
         end
         str.append b

      }

      assert eof?
      str.line=@linenum
      str
end
   ensure
     assign_encoding!(str) if str
   end

   #-----------------------------------
   def dquote_handle(ch)
     @rubyversion >= 1.9 ? dquote19_esc_seq(ch) : dquote_esc_seq(ch) 
     #factored
   end
   #-----------------------------------
   def dquote_handler_name
     @rubyversion>=1.9 ? :dquote19_esc_seq : :dquote_esc_seq
     #factored
   end
   #-----------------------------------
   def Wquote_handler_name
     @rubyversion>=1.9 ? :Wquote19_esc_seq : :Wquote_esc_seq
     #factored
   end

   #-----------------------------------
   ESCAPECHRS="abefnrstv"
   ESCAPESEQS="\a\b\e\f\n\r\s\t\v"
   def dquote_esc_seq(ch,nester=nil,delimiter=nil)
      assert ch == '\\'
      #see pickaxe (1st ed), p 205 for documentation of escape sequences
      return case k=getchar
         when "\n" then @linenum+=1; ""
         when "\\" then "\\"
         when '"' then '"'
         when '#' then '#'
         when /^[#{ESCAPECHRS}]$/o
            k.tr(ESCAPECHRS,ESCAPESEQS)
         when "M"
            eat_next_if(?-) or raise 'bad \\M sequence'
            ch=getchar_maybe_escape[0]
            ch=ch.ord if ch.respond_to? :ord
            ch>=0xFF and raise 'bad \\M sequence'
            (ch | 0x80).chr

         when "C"
            eat_next_if(?-) or raise 'bad \\C sequence'
            nextchar==?? and getchar and return "\177" #wtf?
            ch=getchar_maybe_escape[0]
            ch=ch.ord if ch.respond_to? :ord
            ch>=0xFF and raise 'bad \\M sequence'
            (ch & 0x9F).chr

         when "c"
            nextchar==?? and getchar and return "\177" #wtf?
            ch=getchar_maybe_escape[0]
            ch=ch.ord if ch.respond_to? :ord
            ch>=0xFF and raise 'bad \\M sequence'
            (ch & 0x9F).chr

         when /^[0-7]$/
            str=k
            while str.length < 3
               str << (eat_next_if(/[0-7]/) or break)
            end
            (str.oct&0xFF).chr

         when "x"
            str=''
            while str.length < 2
               str << (eat_next_if(/[0-9A-F]/i) or break)
            end
            str=='' and raise "bad \\x sequence"
            str.hex.chr

         else
            k
      end
   end

   #-----------------------------------
   def dquote19_esc_seq(ch,nester,delimiter)
      assert ch == '\\'
      case ch=getchar
      when 'u'
        case ch=getchar
        when /[a-f0-9]/i
          u=ch+read(3)
          raise "bad unicode escape" unless /[0-9a-f]{4}/i===u
          [u.hex].pack "U"
        when '{'
          result=[]
          until eat_next_if '}'
            u=@file.scan( /\A[0-9a-f]{1,6}[ \t]?/i )
            raise "bad unicode escape" unless u
            result<<u.hex
          end
          result=result.pack "U*"
        else raise "bad unicode escape"
        end 
      else 
        back1char
        result=dquote_esc_seq('\\',nester,delimiter)
        #/\s|\v/===result and result="\\"+result
        result
      end
   end

   #-----------------------------------
   def regex_esc_seq(ch,nester,delimiter)
      assert ch == '\\'
      ch=getchar
      if ch=="\n" 
        @linenum+=1
        return ''
      end
      '\\'+ch
   end

   #-----------------------------------
   def Wquote_esc_seq(ch,nester,delimiter)
      assert ch == '\\'
      case ch=getchar
      when "\n"; @linenum+=1; ch
      when nester,delimiter; ch
      when /[#@@WSCHARS\\]/o; ch
      else 
        back1char
        result=dquote_esc_seq('\\',nester,delimiter)
        #/\s|\v/===result and result="\\"+result
        result
      end
   end

   #-----------------------------------
   def Wquote19_esc_seq(ch,nester,delimiter)
      assert ch == '\\'
      case ch=getchar
      when "\n"; @linenum+=1; ch
      when nester,delimiter; ch
      when /[#@@WSCHARS\\]/o; ch
      else 
        back1char
        result=dquote19_esc_seq('\\',nester,delimiter)
        #/\s|\v/===result and result="\\"+result
        result
      end
   end

   #-----------------------------------
   def wquote_esc_seq(ch,nester,delimiter)
      assert(ch=='\\')

      #get the escaped character
      escchar=getchar
      case escchar
         #all \ sequences 
         #are unescaped; actual
         #newlines are counted but not changed
         when delimiter,nester,'\\'; escchar
#         when delimiter,nester; escchar
         when "\n"; @linenum+=1; escchar
         when /[#@@WSCHARS]/o; escchar
         else       "\\"+escchar
      end
   end

   #-----------------------------------
   def squote_esc_seq(ch,nester,delimiter)
      assert(ch=='\\')

      #get the escaped character
      escchar=getchar
      case escchar
         #all \ sequences 
         #are unescaped; actual
         #newlines are counted but not changed
         when delimiter,nester,'\\'; escchar
#         when delimiter,nester; escchar
         when "\n"; @linenum+=1; "\\"+escchar
         else       "\\"+escchar
      end
   end

   #-----------------------------------
   def squote_heredoc_esc_seq(ch,nester,delimiter)
      assert(ch=='\\')

      #get the escaped character
      escchar=getchar
      case escchar
         #all \ sequences 
         #are unescaped; actual
         #newlines are counted but not changed
         when delimiter,nester; escchar
#         when delimiter,nester; escchar
         when "\n"; @linenum+=1; "\\"+escchar
         else       "\\"+escchar
      end
   end

=begin
   #-----------------------------------
   def squote_esc_seq(ch,nester,delimiter)
      assert(ch=='\\')

      #get the escaped character
      escchar=getchar
      escchar=="\n" and @linenum+=1
      escchar="\\"+escchar unless escchar[/['\\]/]
      return escchar
   end
=end
#   alias squote_esc_seq	wquote_esc_seq

  module RecursiveRubyLexer
=begin
    def initial_nonblock_levels
      @localvars_stack.size==1 ? 2 : 1
    end
=end
  end

  def initial_nonblock_levels; 1 end
  def first_current_level
    result=@localvars_stack.last.__locals_lists.size-initial_nonblock_levels 
    result=[initial_nonblock_levels,result].max
    result
  end

  def merge_levels levels, nil_empty_class
    case (levels.size rescue 0)
    when 0; {} unless nil_empty_class
    when 1; levels.first.dup
    else levels.inject{|a,b| a.merge b} 
    end
  end

  def decompose_lvars(nil_empty_class=false)
    levels=
      @localvars_stack.last.__locals_lists
    nonblocky=merge_levels levels[0...initial_nonblock_levels], nil_empty_class
    blocky=merge_levels levels[initial_nonblock_levels...first_current_level], nil_empty_class
    current=merge_levels levels[first_current_level..-1], nil_empty_class
    return nonblocky,blocky,current
  end
   
  def new_lvar_type
    size=@localvars_stack.last.__locals_lists.size
    return :local if size<=initial_nonblock_levels
    return :block if size<first_current_level
    return :current
  end

  def lvar_type(name)
    nonblocky,blocky,current=decompose_lvars
    nonblocky[name] and return :local 
    blocky[name] and return :block 
    current[name] and return :current
    return new_lvar_type
  end

  def assign_lvar_type!(vartok)
    vartok.respond_to? :lvar_type= and
      vartok.lvar_type=lvar_type(vartok.ident)
    return vartok
  end
   
   #-----------------------------------
   def ruby_code(ch='{')
      assert ch[/^[{(@$]$/]
      klass= RubyLexer===self ? self.class : RubyLexer
      rl=klass.new(@filename,@file,@linenum,offset_adjust(),:rubyversion=>@rubyversion)
      rl.extend RecursiveRubyLexer
      rl.enable_macros! if @enable_macro
      rl.in_def=true if inside_method_def?
#      rl.offset_adjust_set! offset_adjust()
      assert offset_adjust()==rl.offset_adjust()

      #pass current local vars into new parser
      #must pass the lists of nonblock, parentblock and currentblock vars separately
      #then a table increment after each
      rl.localvars_stack=@localvars_stack.map{|lvs| lvs.deep_copy}
      
      rl.pending_here_bodies=@pending_here_bodies

      case ch
      when '@'
         tokens=[rl.at_identifier]
      when '$'
         tokens=[rl.dollar_identifier]
      when '{'#,'('
         tokens=[]
         loop {
            tok=rl.get1token
            tokens << tok
            if EoiToken===tok
              lexerror tok,"unterminated string inclusion"
              break
            end
            if tok==='}'
              if ErrorToken===tok #mismatched?
                parsestack[1..-1].reverse_each{|ctx|
                  tok.error<< "\nno end found for #{ctx.class}"
                }
                break
              end
              break if rl.no_more? and rl.balanced_braces?
            end
         }
      else
         raise 'hell'
      end

=begin
      if @linenum != rl.linenum
        last=tokens.pop
        fal=FileAndLineToken.new(@filename,@linenum, last.offset)
        tokens.push fal,last
      end
=end

      #need to verify that rl's @moretokens, @incomplete_here_tokens are empty
      rl.incomplete_here_tokens.empty? or 
        here_spread_over_ruby_code rl,tokens.last
      rl.no_more? or
        raise 'uh-oh, ruby tokens were lexed past end of ruby code'

      #assert offset_adjust()==rl.offset_adjust() #|| rl.offset_adjust().zero?
      @offset_adjust=rl.offset_adjust

      #input_position_set rl.input_position_raw
      @file=rl.file
#      @pending_here_bodies=rl.pending_here_bodies      

      #local vars defined in inclusion get propagated to outer parser
      @localvars_stack=rl.localvars_stack

      result=RubyCode.new(tokens,@filename,@linenum)
      @linenum=rl.linenum
      return result
   end
   

   #-----------------------------------
#   BINCHARS=?0..?1
#   OCTCHARS=?0..?7
#   DECCHARS=?0..?9
#   HEXCHARS=CharSet[?0..?9, ?A..?F, ?a..?f]
   BINCHARS=/[01_]+/
   OCTCHARS=/[0-7_]+/
   allowed=/[0-9_]/
   DECCHARS=/^#{allowed}*(\.(?!_)#{allowed}+)?([eE](?!_)(?:[+-])?#{allowed}+)?/
   HEXCHARS=/[0-9a-f_]+/i
   DECIMAL_INT_INTERP=:to_s
   ARBITRARY_INT_INTERP=:to_s
   NUMREXCACHE={}
   #0-9
   #-----------------------------------
   def number(str)

      return nil unless /^[0-9+\-]$/===str

      interp=DECIMAL_INT_INTERP
      str=  (eat_next_if(/[+\-]/)or'')
      str<< (eat_next_if(?0)or'')

      if str[-1] == ?0 and !eof? 
        if nextchar.chr[/[bodx]/i]
          typechar=eat_next_if(/[bodx]/i)
          str << typechar
          interp=ARBITRARY_INT_INTERP
          allowed=case typechar
            when 'b','B'; BINCHARS
            when 'x','X'; HEXCHARS
            when 'o','O'; OCTCHARS
            when 'd','D'; DECCHARS
            else raise  :impossible
          end
        elsif /[.e]/i===nextchar.chr
          interp=ARBITRARY_INT_INTERP
          allowed=DECCHARS
        else
          interp=ARBITRARY_INT_INTERP
          allowed=OCTCHARS
        end
      else
         interp=DECIMAL_INT_INTERP
         allowed =DECCHARS
      end

      #allowed = NUMREXCACHE[allowed] ||= /^#{allowed}*(\.(?!_)#{allowed}+)?([eE](?!_)(?:[+-])?#{allowed}+)?/
      str<<(@file.scan(allowed)||'')
      interp=:to_s if $1 or $2
      return NumberToken.new(str.send(interp))

=begin
      addl_dig_seqs= (typechar)? 0 : 2      #den 210
      error=nil
      
#      @file.each_byte { |b|
#         if unallowed === b or ?_ == b
#            str << b
#         else
       str<<til_charset(unallowed)
       b=getc
            #digits must follow and precede . and e
            if ?.==b and addl_dig_seqs==2 and !(unallowed===nextchar.chr)
               #addl_dig_seqs=1
               str << b
               str<<til_charset(unallowed)
               b=getc
               interp=:to_s
            end
            #digits must follow and precede . and e
            if (?e==b or ?E==b) and addl_dig_seqs>=1 and
                  readahead(2)[/^[-+]?[0-9]/]
               #addl_dig_seqs=0
               str << b
               str << (eat_next_if(/[+\-]/)or'')
               str<<til_charset(unallowed)
               b=getc
               interp=:to_s
            end
               back1char if b
               #return(str.send(interp))
#               break
#            #OCTCHARS allowed here to permit constants like this: 01.2
#            unallowed == DECCHARS or unallowed == OCTCHARS or error= "floats are always decimal (currently)"
#            unallowed = DECCHARS
#            interp=:to_s
#         end
#      }

      assert(str[/[0-9]/])
      lexerror NumberToken.new(str.send(interp)), error
=end
   end

if (defined? DEBUGGER__ or defined? Debugger) 
   #-----------------------------------
   def comment(str=nil)
      #assert str == '#'
      Process.kill("INT",0) if readahead(11)==%/#breakpoint/ 
     
      IgnoreToken.new(til_charset(/\n/))
   end
else
   #-----------------------------------
   def comment(str=nil)
      IgnoreToken.new(til_charset(/\n/))
   end
end
  alias rulexer_comment comment

   #-----------------------------------
   def whitespace(ch)
      assert ch[/^[#{WHSP}]$/o]
      oldpos= input_position
      str=til_charset(/[^#{WHSP}]/o)
      return WsToken.new(str,oldpos)
   end

   #-----------------------------------
   INET_NL_REX=/^(\r\n?|\n\r?)/
   def readnl
      #compatible with dos style newlines...

      eof? and return ''

      nl=readahead(2)[/\A\r?\n/]
      nl or return nil
      assert((1..2)===nl.length)
      @linenum+=1
      read nl.length
   end

   #-----------------------------------
   def newline(ch)
      offset= input_position
      @file.read1
      @linenum+=1
      @moretokens << FileAndLineToken.new( @filename, @linenum, offset+1 )
      return NewlineToken.new("\n",offset)
   end
   alias rulexer_newline newline

   #-----------------------------------
   def getchar_maybe_escape
      eof? and raise "unterminated dq string"
      c=getc.chr

      if c == "\\"
         c = dquote_handle('\\') #@rubyversion >= 1.9 ? dquote19_esc_seq('\\') : dquote_esc_seq('\\')
         c = "\n" if c.empty?
      end
      return c
   end

protected
#  delegate_to :@file, :eat_next_if,:prevchar,:nextchar,:getchar,:getc,:back1char
  require 'forwardable'
  extend Forwardable
  def_delegators :@file, :readahead, :readback, :read, :eof?
  alias rulexer_eof? eof?

  def til_charset cs,len=16; @file.read_til_charset cs,len end
  def getc; @file.read1 end
  def getchar; @file.read 1 end
  def back1char; @file.move( -1 )end
  def prevchar; @file.readbehind 1 end
  def nextchar; @file.readahead1 end

  #-----------------------------------
  def eat_next_if(ch)
    saw=getc or return
    if Integer===ch
      ch==saw
    else
      ch===saw.chr
    end or (back1char; return)
    return saw.chr
  end

  #-----------------------------------
  def eat_if(pat,count)
    oldpos=@file.pos
    saw=read count
    if pat===saw 
      return saw
    else 
      @file.pos=oldpos
      return nil
    end
  end

  #-----------------------------------
  def input_position; @file.pos end
  alias rulexer_input_position input_position

  #-----------------------------------
  def input_position_set x; @file.pos=x end

  #-----------------------------------
  def adjust_linenums_in_moretokens!(tok2)
    line=tok2.endline
    @moretokens.each{|tok|
      if tok.linecount.zero?
        tok.endline||=line
      else
        line+=tok.linecount
      end
    }
  end

  #-----------------------------------
  def self.save_offsets_in(*funcnames)
    eval funcnames.collect{|fn| <<-endeval }.join
      class ::#{self}
        alias #{fn}__no_offset #{fn}   #rename old ver of fn
        def #{fn}(*args)               #create new version
          pos= input_position
          ln=@linenum
          result=#{fn}__no_offset(*args)
          assert Token===result, "lexer output was not a Token"
          result.offset||=pos
          result.endline||=ln
          adjust_linenums_in_moretokens!(result)
          return result
        end
      end
    endeval
  end

  #-----------------------------------
  def self.save_linenums_in(*funcnames)
    eval funcnames.collect{|fn| <<-endeval }.join
      class ::#{self}
        alias #{fn}__no_linenum #{fn}   #rename old ver of fn
        def #{fn}(*args)               #create new version
          ln=@linenum
          result=#{fn}__no_linenum(*args)
          assert Token===result
          result.endline||=ln
          adjust_linenums_in_moretokens!(result)
          return result
         end
      end
    endeval
  end


end



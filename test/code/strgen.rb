module Strgen
  PAIRS=[
    ['<','>'],
    ['(',')'],
    ['[',']'],
    ['{','}']
  ]
  ALLOWED_UNNESTING_FANCY=/[^<>\[\]{}()a-z0-9_]/i
  FANCY_TYPES=%w[q Q r s x w W]<<''
  SIMPLE_QUOTES=%w[" ' / `]
  SIMPLE_ESCAPES=%w[s n r t v f a b e]
  MULTI_ESCAPES=%w[x c C M 0 1 2 3 4 5 6 7]
  NON_ESCAPES=/[^#{SIMPLE_ESCAPES+MULTI_ESCAPES}]/

  def Strgen.rand_char_including(allow,disallow='')
    q=nil
    q=rand(255).chr until ((allow===q) and not (disallow[q]))
    q
  end

  def Strgen.rand_esc_seq(disallow,bsonly)
    limit=4
    bsonly[/\\/] and disallow+='\\'
    (disallow['#'] or bsonly['#']) and limit=3
    choice=rand limit
    choice=3 if disallow[/\\/] or bsonly[/\#/]
    case choice
    when 0: "\\"+rand_char_including(NON_ESCAPES,disallow)
    when 1: "\\"+SIMPLE_ESCAPES[rand(SIMPLE_ESCAPES.size)]
    when 2:
      "\\"+
      case ch=MULTI_ESCAPES[rand(MULTI_ESCAPES.size)]
      when "x": "x"+rand(256).to_s(16)
      when "0".."7": rand(256).to_s(8)
      when "c": 
        "c"+
        if rand(2).zero?
          rand_char_including(/[^\\]/,disallow+bsonly)
        else
          rand_esc_seq disallow+"#",bsonly
        end
      when "C","M":
        return rand_esc_seq(disallow,bsonly) if disallow['-'] or bsonly['-']
        ch+"-"+
        if rand(2).zero?
          rand_char_including(/[^\\]/,disallow+bsonly)
        else
          rand_esc_seq disallow+"#",bsonly
        end
      end
    when 3:
      '#{'+rand(9999999999).to_s+'}'
    end
  end
  
  CACHE={}

  def Strgen.strgen
    must_be_escaped="#\\"
    case rand(3)
    when 0
      starter=ender=SIMPLE_QUOTES[rand(SIMPLE_QUOTES.size)]
      must_be_escaped<<starter
    when 1
      type=FANCY_TYPES[rand(FANCY_TYPES.size)]
      pair=PAIRS[rand(PAIRS.size)]
      starter= "%"+type+pair[0]
      ender= pair[1]
      must_be_escaped<<pair.to_s
    when 2
      type=FANCY_TYPES[rand(FANCY_TYPES.size)]
      q=rand_char_including ALLOWED_UNNESTING_FANCY
      /w/i===type and /\s|\v/===q and q='"'
      starter= "%"+type+q
      ender=q
      must_be_escaped<<q
    end
  
    if starter=="/" or type=='r'
      must_be_escaped+="[]{}()?+*"
    end
    must_be_escaped+="\0" if type=='s'
    ckey=must_be_escaped
    ordinary=
      CACHE[ckey]||=
        /[^#{must_be_escaped.gsub(/./){"\\"+$&}}]/

    interior=(1..rand(40)).map{|x|
      rand_char_including ordinary
    }.to_s

    interior["\\"] and fail

    disallow=''
    bsonly=starter[-1,1]+ender
#    disallow+='#' if /[\#\\\-]/===starter[-1,1]
#    disallow+=starter[-1,1]+ender if type=='r' or starter=='/'
    disallow+="\0" if type=='s'
    disallow+=must_be_escaped.gsub('\\','') if type=='r' or starter=='/'

    poslimit=interior.size+1
    rand(5).times{
      pos=rand poslimit
      interior[pos,0]=rand_esc_seq disallow,bsonly
      poslimit=pos
    } unless starter[-1]==?\\

    interior.gsub!(/\\[a-z]/i,'') if type=='r' or starter=='/'

    starter[-1]==?\r and interior.gsub!(/\A\n+/,'')

    starter[1]==?s and interior=='' and interior="x"

    result= starter+interior+ender

    begin
      begin eval "BEGIN{break};proc() do #{result} end" end while false
    rescue Exception
      #puts %<failing string: eval "#{result.gsub(/./){'\\x'+$&[0].to_s(16)}}">
      return strgen
    end

    return result
  end
end

if __FILE__==$0
start=Time.now
i=0
10_000_000.times{|i|
  begin
    ss=Strgen.strgen
    RubyLexerVsRuby.rubylexervsruby "-e#{i}", ss
  rescue Exception
    puts %<failing string: eval "#{ss.gsub(/./){'\\x'+$&[0].to_s(16)}}">
  end
}
end

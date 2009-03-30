require 'test/code/rubylexervsruby'
opts = GetoptLong.new( [ '--ends', '-e', GetoptLong::OPTIONAL_ARGUMENT] )
endcount=0
opts.each {|opt,arg|
  if opt=='--ends'
    if arg==''
      endcount=1
    else
      endcount=arg.to_i
    end
  end
}

ends="end\n"*endcount

endcode=ends#+"__END__\n"

lines=IO.readlines(ARGV.first)

low=1
high=lines.size-1

class DontEvalThis<Exception; end

def syntax_ok?(code)
  caught=
  begin
    catch :dontevalthis do
      eval "
        BEGIN{throw :dontevalthis, :notevaled}
        BEGIN{raise DontEvalThis}
      "+code
    end
  rescue DontEvalThis:
    puts "first level eval barrier failed!!!"
    caught=:notevaled
  rescue Exception:
    caught=:unexpected
  end
  case caught
  when :unexpected
    return false
  when :notevaled
    return true
  else #wtf?
    puts "eval barriers totally bypassed?!?!?"
  end
end

span=9999999999999999999999999999
loop do
  break if high-low>=span
  span=high-low
  adjust=1
  mid=(low+high)/2
  begin
    text=lines.dup
    realmid=mid+adjust
    realmid=[[realmid,low].max,high].min
    text=text[0...realmid] << endcode
    text=text.to_s
    adjust*=-2
  end until syntax_ok?text
  
  if RubyLexerVsRuby.rubylexervsruby(ARGV.first+".chunk#{low..high}", text)
    low=realmid
  else
    high=realmid
  end
end

p low..high

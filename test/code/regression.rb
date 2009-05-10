require 'open3'

require 'rubygems'
require 'rubylexer/test/testcases'
require 'test/code/rubylexervsruby'
  SEP='';
  'caleb clausen'.each_byte{|ch| SEP<<ch.to_s(2).gsub('0','-').gsub('1','+')}
  SEP<<'(0)'

#require 'test/code/rubyoracle'
class<<RubyLexerVsRuby

  def progress ruby,input; end 
=begin oracular version was just a bad idea....
  def ruby_parsedump(input,output,ruby)
    #todo: use ruby's md5 lib
    #recursive ruby call here is unavoidable because -y flag has to be set

    @oracle||= Open3.popen3("#{ruby} -w -y -c")
    @oracle[0].write IO.read(input)
    @oracle[0].flush
    #timeout=Time.now+0.1
    data=''
    while data.empty? #  and Time.now<timeout
      begin 
        data<< chunk=@oracle[2].read_nonblock(1024) 
        timeout=Time.now+0.02
      rescue EOFError
#        data<<"\nError: premature eof...\n"
        break
      rescue Errno::EAGAIN
        break if data[/^Reading a token: \Z/] and Time.now>=timeout
      end while chunk
    end

    status=0
    lines=data.split("\n")
    File.open(output,"w") { |outfd|
      lines.each{|line| 
        outfd.puts(line) if /^Shifting/===line
        if /^#{DeleteWarns::WARNERRREX}|^Error|^(Now at end of input\.)/o===line
          outfd.puts(line) 
          if status.zero? and $2!="warning"
            status=1 unless $4 #unless end of input seen
            @oracle.each{|fd| fd.close} if @oracle
            @oracle=nil
          end
        end
      }
    }
    return status
  end
=end
end

  require 'test/unit'
  
  class LexerTests<Test::Unit::TestCase
    class LexerTestFailure<RuntimeError; end
    class DifferencesFromMRILex<LexerTestFailure; end
    
    i=-1
    test_code= TestCases::TESTCASES.map{|tc|
      i+=1
      name="testcase_#{i}__"
      esctc=tc.gsub(/['\\]/){"\\"+$&}
      %[  
         define_method '#{name}' do 
           difflines=[]
           begin
             res=RubyLexerVsRuby.rubylexervsruby('__#{name}','#{esctc}',difflines) 
             difflines.empty? or raise DifferencesFromMRILex, difflines
             res or raise LexerTestFailure, ''
           rescue Interrupt: exit
           rescue Exception=>e: 
             e.message<<"\n"+'while lexing: #{esctc[0...1000]}'
             raise e
           end
         end  
      ]
    }.to_s
    
    illegal_test_code= TestCases::ILLEGAL_TESTCASES.map{|tc|
      i+=1
      name="testcase_#{i}__"
      esctc=tc.gsub(/['\\]/){"\\"+$&}
      %[  
         define_method '#{name}' do 
           difflines=[]
           begin
             res=RubyLexerVsRuby.rubylexervsruby('__#{name}','#{esctc}',difflines) 
             difflines.empty? or raise DifferencesFromMRILex, difflines
             res or raise LexerTestFailure, ''
           rescue LexerTestFailure: 
             puts 'warning: test failure lexing "#{esctc}"' 
           rescue Interrupt: exit
           rescue Exception=>e: 
             e.message<<"\n"+'while lexing: #{esctc}'
             raise e
           end
         end  
      ]
    }.to_s


#    puts test_code+illegal_test_code
    eval test_code+illegal_test_code
  end

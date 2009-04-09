module TestCases
#  fail unless File.exist 'test/data/oneliners.rb' and  File.exist 'test/data/stanzas.rb'
  rldir=$:.find{|dir| File.exist? dir+'/rubylexer/test/oneliners.rb' and  File.exist? dir+'/rubylexer/test/stanzas.rb' }
  ONELINERS=IO.readlines(rldir+'/rubylexer/test/oneliners.rb').map{|x| x.chomp}.grep(/\A\s*[^#\s\n]/).reverse
  STANZAS=IO.read(rldir+'/rubylexer/test/stanzas.rb').split("\n\n").grep(/./).reverse
  STANZAS.each{|stanza| stanza<<"\n" }
  ILLEGAL_ONELINERS=IO.readlines(rldir+'/rubylexer/test/illegal_oneliners.rb').map{|x| x.chomp}.grep(/\A\s*[^#\s\n]/).reverse
  ILLEGAL_STANZAS=IO.read(rldir+'/rubylexer/test/illegal_stanzas.rb').split("\n\n").grep(/./).reverse
  TESTCASES=ONELINERS+STANZAS
  ILLEGAL_TESTCASES=ILLEGAL_ONELINERS+ILLEGAL_STANZAS
end

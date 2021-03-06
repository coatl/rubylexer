module TestCases
#  fail unless File.exist 'test/data/oneliners.rb' and  File.exist 'test/data/stanzas.rb'
  rldir=$:.find{|dir| File.exist? dir+'/rubylexer/test/oneliners.rb' and  File.exist? dir+'/rubylexer/test/stanzas.rb' }
  ONELINERS=IO.readlines(rldir+'/rubylexer/test/oneliners.rb').map{|x| x.chomp}.grep(/\A\s*[^#\s]/).reverse
  STANZAS=IO.read(rldir+'/rubylexer/test/stanzas.rb').split("\n\n").grep(/./).reverse
  STANZAS.each{|stanza| stanza<<"\n" }
  ILLEGAL_ONELINERS=IO.readlines(rldir+'/rubylexer/test/illegal_oneliners.rb').map{|x| x.chomp}.grep(/\A\s*[^#\s]/).reverse
  ILLEGAL_STANZAS=IO.read(rldir+'/rubylexer/test/illegal_stanzas.rb').split("\n\n").grep(/./).reverse

  datadir=$:.find{|dir| File.exist? dir+'/../test/data/p.rb' }
  FILENAMES=Dir[datadir+'/../test/data/*.rb'].reject{|fn| File.directory? fn}
  FILES=FILENAMES.map{|fn| File.read fn }

  ILLEGAL_FILENAMES=(Dir[datadir+'/../test/data/*']-Dir[datadir+'/../test/data/*.rb'])
  ILLEGAL_FILENAMES.reject!{|fn| File.directory? fn}
  ILLEGAL_FILES=ILLEGAL_FILENAMES.map{|fn| File.read fn }

  TESTCASES=ONELINERS+STANZAS+FILES
  ILLEGAL_TESTCASES=ILLEGAL_ONELINERS+ILLEGAL_STANZAS+ILLEGAL_FILES
end

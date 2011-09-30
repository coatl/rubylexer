require 'rbconfig'
conf=RbConfig::CONFIG
ruby=conf['bindir']+"/"+conf['RUBY_INSTALL_NAME']
ruby='ruby' unless File.exist? ruby


fail unless system(ruby,  "-e", <<END)
   begin; 
     require '#{File.expand_path(File.join( File.dirname(__FILE__),'bad/ruby_lexer' ))}';  
     require 'rubygems'
     require 'rubylexer';  
     rl=RubyLexer.new('eval','eval'); 
       fail if $the_wrong_rubylexer==1;
   end;
END


require 'rbconfig'
conf=RbConfig::CONFIG
ruby=conf['bindir']+"/"+conf['RUBY_INSTALL_NAME']
ruby='ruby' unless File.exist? ruby


fail unless system(ruby,  "-e", <<END)
   class X<RuntimeError; end;
   begin; 
     require '#{File.expand_path(File.join File.dirname(__FILE__),'bad/ruby_lexer')}';  
     require 'rubylexer';  
     rl=RubyLexer.new('eval','eval'); 
     raise X;
     rescue X; 
       fail if $the_wrong_rubylexer==1;
     rescue Exception; fail;
     else fail;
   end;
END


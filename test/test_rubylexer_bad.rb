alias orig_warn warn
def warn x; end;

begin;
    require 'rubylexer';
    require 'test/bad/ruby_lexer';
    rl=RubyLexer.new('eval','eval');
rescue Exception;
else fail if $the_wrong_rubylexer
end

alias warn orig_warn

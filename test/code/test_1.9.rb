require 'test/unit'
require "rubylexer"

class Ruby1_9Tests < Test::Unit::TestCase
  EXPECT_NO_METHODS=[ #no errors either
    '->a; h do 123 end',
    '->{}',
    '-> {}',
    '->;{}',
    '->(;){}',
    '->a{}',
    '->a {}',
    '->a;{}',
    '->(a;){}',
    '->a,b{}',
    '->a,b;{}',
    '->a,b;c{}',
    '->(a,b;){}',
    '->(a,b;c){}',
    '$f.($x,$y)',
    '$f::($x,$y)',
    '__ENCODING__',
    'module __ENCODING__::A; end',
  ]

  EXPECT_1_METHOD=[
    'def self.foo; 1 end',
    '->{ foo=1 }; foo',
    '->do foo=1 end; foo',
    'def __ENCODING__; 342 end',
    'def __ENCODING__.foo; 1 end',
    'def __FILE__.foo; 1 end',
    'def __LINE__.foo; 1 end',
    'def a(b,*c,d) 1 end',
    'def a(*c,d) 1 end',
    'a{|b,*c,d| 1 }',
    'a{|*c,d| 1 }',
    'def a(b,(x,y),d) 1 end',
    'def a((x,y),d) 1 end',
    'a{|b,(x,y),d| 1 }',
    'a{|(x,y),d| 1 }',
    'def a(b,(x,*y),d) 1 end',
    'def a((x,*y),d) 1 end',
    'a{|b,(x,*y),d| 1 }',
    'a{|(x,*y),d| 1 }',
    'def a(b,(x,(y,z)),d) 1 end',
    'def a((x,(y,z)),d) 1 end',
    'a{|b,(x,(y,z)),d| 1 }',
    'a{|(x,(y,z)),d| 1 }',
    'module __ENCODING__::A include B; end',
  ]

  def test_1_9_roughly
    EXPECT_NO_METHODS.each{|snippet| 
      begin
        tokens=RubyLexer.new('string',snippet,1,0,:rubyversion=>1.9).to_a
        assert_equal [],tokens.grep(RubyLexer::MethNameToken)
        assert_equal [],tokens.grep(RubyLexer::ErrorToken)
      rescue Exception=>e
        raise e.class.new(e.message+" while testing '#{snippet}'")
      end
    }
    EXPECT_1_METHOD.each{|snippet| 
      begin
        tokens=RubyLexer.new('string',snippet,1,0,:rubyversion=>1.9).to_a
        assert_equal 1,tokens.grep(RubyLexer::MethNameToken).size
        assert_equal [],tokens.grep(RubyLexer::ErrorToken)
      rescue Exception=>e
        raise e.class.new(e.message+" while testing '#{snippet}'")
      end
    }
  end
end

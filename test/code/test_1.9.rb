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
  ]

  def test_stabby_roughly
    EXPECT_NO_METHODS.each{|snippet| 
      begin
        tokens=RubyLexer.new('string',snippet,1,0,:rubyversion=>1.9).to_a
        assert_equal [],tokens.grep(RubyLexer::MethNameToken)
        assert_equal [],tokens.grep(RubyLexer::ErrorToken)
      rescue Exception=>e
        raise e.class.new(e.message+" while testing '#{snippet}'")
      end
    }
  end
end

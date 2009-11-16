require 'test/unit'
require "rubylexer"
require "rubylexer/test/oneliners_1.9"

class Ruby1_9Tests < Test::Unit::TestCase
  include Ruby1_9OneLiners
  def test_1_9_roughly
    EXPECT_NO_METHODS.each{|snippet| 
      begin
        tokens=RubyLexer.new('string',snippet,1,0,:rubyversion=>1.9).to_a
        assert_equal [],tokens.grep(RubyLexer::MethNameToken)
        assert_equal [],tokens.grep(RubyLexer::ErrorToken)
      rescue Exception=>e
        e2=e.class.new(e.message+" while testing '#{snippet}'")
        e2.set_backtrace(e.backtrace)
        raise e2
      end
    }
    EXPECT_1_METHOD.each{|snippet| 
      begin
        tokens=RubyLexer.new('string',snippet,1,0,:rubyversion=>1.9).to_a
        assert_equal 1,tokens.grep(RubyLexer::MethNameToken).size
        assert_equal [],tokens.grep(RubyLexer::ErrorToken)
      rescue Exception=>e
        e2=e.class.new(e.message+" while testing '#{snippet}'")
        e2.set_backtrace(e.backtrace)
        raise e2
      end
    }
  end
end

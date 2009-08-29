require 'test/unit'
require "rubylexer"

class Ruby1_9Tests < Test::Unit::TestCase
  def test_stabby_roughly
    tokens=RubyLexer.new('string','->a; h do 123 end').to_a

    assert_equal tokens.grep(RubyLexer::MethNameToken),[]
  end
end

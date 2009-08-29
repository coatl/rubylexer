require 'test/unit'
require "rubylexer"

class Ruby1_9Tests < Test::Unit::TestCase
  def test_stabby_roughly
    tokens=RubyLexer.new('string','->a; h do 123 end',1,0,:rubyversion=>1.9).to_a
    assert_equal [],tokens.grep(RubyLexer::MethNameToken)

    tokens=RubyLexer.new('string','->{}',1,0,:rubyversion=>1.9).to_a
    assert_equal [],tokens.grep(RubyLexer::ErrorToken)

    tokens=RubyLexer.new('string','-> {}',1,0,:rubyversion=>1.9).to_a
    assert_equal [],tokens.grep(RubyLexer::ErrorToken)

    tokens=RubyLexer.new('string','->;{}',1,0,:rubyversion=>1.9).to_a
    assert_equal [],tokens.grep(RubyLexer::ErrorToken)

    tokens=RubyLexer.new('string','->a{}',1,0,:rubyversion=>1.9).to_a
    assert_equal [],tokens.grep(RubyLexer::ErrorToken)
    assert_equal [],tokens.grep(RubyLexer::MethNameToken)

    tokens=RubyLexer.new('string','->a {}',1,0,:rubyversion=>1.9).to_a
    assert_equal [],tokens.grep(RubyLexer::ErrorToken)
    assert_equal [],tokens.grep(RubyLexer::MethNameToken)

    tokens=RubyLexer.new('string','->a;{}',1,0,:rubyversion=>1.9).to_a
    assert_equal [],tokens.grep(RubyLexer::ErrorToken)
    assert_equal [],tokens.grep(RubyLexer::MethNameToken)

    tokens=RubyLexer.new('string','->a,b{}',1,0,:rubyversion=>1.9).to_a
    assert_equal [],tokens.grep(RubyLexer::ErrorToken)
    assert_equal [],tokens.grep(RubyLexer::MethNameToken)

    tokens=RubyLexer.new('string','->a,b;{}',1,0,:rubyversion=>1.9).to_a
    assert_equal [],tokens.grep(RubyLexer::ErrorToken)
    assert_equal [],tokens.grep(RubyLexer::MethNameToken)

    tokens=RubyLexer.new('string','->a,b;c{}',1,0,:rubyversion=>1.9).to_a
    assert_equal [],tokens.grep(RubyLexer::ErrorToken)
    assert_equal [],tokens.grep(RubyLexer::MethNameToken)
  end
end

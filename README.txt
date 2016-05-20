= RubyLexer

* rubyforge.net/projects/rubylexer
* github.com/coatl/rubylexer

=== DESCRIPTION:

RubyLexer is a lexer library for Ruby, written in Ruby. Rubylexer is meant
as a lexer for Ruby that's complete and correct; all legal Ruby 
code should be lexed correctly by RubyLexer as well. Just enough parsing 
capability is included to give RubyLexer enough context to tokenize correctly
in all cases. (This turned out to be more parsing than I had thought or 
wanted to take on at first.) RubyLexer handles the hard things like 
complicated strings, the ambiguous nature of some punctuation characters and 
keywords in ruby, and distinguishing methods and local variables. It should
be able to correctly lex 99.9+% of legal ruby code.

RubyLexer is not particularly clean code. As I progressed in writing this, 
I've learned a little about how these things are supposed to be done; the 
lexer is not supposed to have any state of it's own, instead it gets whatever 
it needs to know from the parser. As a stand-alone lexer, Rubylexer maintains 
quite a lot of state. Every instance variable in the RubyLexer class is some 
sort of lexer state. Most of the complication and ugly code in RubyLexer is 
in maintaining or using this state.

For information about using RubyLexer in your program, please see howtouse.txt.

For my notes on the testing of RubyLexer, see testing.txt.

If you have any questions, comments, problems, new feature requests, or just
want to figure out how to make it work for what you need to do, contact me: 
       rubylexer _at_ inforadical _dot_ net

Bugs or problems with rubylexer should be submitted to the bug stream for 
rubylexer's github project: http://github.com/coatl/rubylexer/bugs


==SYNOPSIS:
require "rubylexer.rb"
 #then later
lexer=RubyLexer.new(a_file_name, opened_File_or_String)
until EoiToken===(token=lexer.get1token)
  #...do stuff w/ token...
end

== Status
RubyLexer can correctly lex all legal Ruby 1.8 and 1.9 code that I've been able to 
find. (And I've found quite a bit.)

It can also handle (most of) my catalog of nasty 
test cases (see below for known problems). Modulo some very obscure bugs,
RubyLexer can correctly distinguish these ambiguous uses of the following 
operators, depending on context:
  %   can be modulus operator or start of fancy string
  /   can be division operator or start of regex
  * & + - :: can be unary or binary operator
  []  can be for array literal or [] method (or []=)
  <<  can be here document or left shift operator (or in class<<obj expr)
  :   can be start of symbol, substitute for then, or part of ternary op
      (there are other uses too, but they're not supported yet.)
  ?   can be start of character constant or ternary operator
  `   can be method name or start of exec string
  any overrideable operator and most keywords can also be method names

== todo
test more ways: cvt source to dos or mac fmt before testing
test more ways: test require'd, load'd, or eval'd code as well (0.7)
lex code a line (or chunk) at a time and save state for next line (irb wants this) (0.8)
incremental lexing (ides want this (for performance))
put everything in a namespace
integrate w/ other tools...
html colorized output?
move more state onto @parsestack (ongoing)
expand on test documentation
use want_op_name more
return result as a half-parsed tree (with parentheses and the like matched)
emit advisory tokens when see beginword, then (or equivalent), or end... what else does florian want?
emit advisory tokens when local var defined/goes out of scope (or hidden/unhidden?)
token pruning in dumptokens...

== known issues: (and planned fix release)
context not really preserved when entering or leaving string inclusions. this caused
-a number or problems, which had to be hacked around. it would be better to avoid
-tokens within tokens. (0.8)
string contents might not be correctly translated in a few cases (0.8?)
'\r' whitespace sometimes seen in dos-formatted output.. shouldn't be (eg pre.rb) (0.7)
windows newline in source is likely to cause problems in obscure cases (need test case)
current character set is always forced to ascii-8bit. however, this mode should be
-compatible with texts written in regular ascii, utf-8, and euc. (among others?) (1.0)
regression test currently shows a few errors with differences in exact token ordering
-around string inclusions. these errors are much less serious than they seem.
offset of AssignmentRhsListEndToken appears to be off by 1
offset of Here document bodies appear to be off by 1 sometimes
newline inserted at eof in texts which end with heredoc but no nl
token offsets after here documents are now off
unlexing of here document body in the middle of an otherwise unsuspecting
-string lexes wrong. (still parses ok, tho, even so.)

= RubyLexer

*
*
*

=== DESCRIPTION:

RubyLexer is a lexer library for Ruby, written in Ruby. Rubylexer is meant
as a lexer for Ruby that's complete and correct; all legal Ruby 
code should be lexed correctly by RubyLexer as well. Just enough parsing 
capability is included to give RubyLexer enough context to tokenize correctly
in all cases. (This turned out to be more parsing than I had thought or 
wanted to take on at first.) RubyLexer handles the hard things like 
complicated strings, the ambiguous nature of some punctuation characters and 
keywords in ruby, and distinguishing methods and local variables.

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

RubyLexer is a RubyForge project. RubyForge is another good place to send your
bug reports or whatever:  http://rubyforge.org/projects/rubylexer/

(There aren't any bug filed against RubyLexer there yet, but don't be afraid 
that your report will get lonely.)

==SYNOPSIS:
require "rubylexer.rb"
 #then later
lexer=RubyLexer.new(a_file_name, opened_File_or_String)
until EoiToken===(token=lexer.get1token)
  #...do stuff w/ token...
end

== Status
RubyLexer can correctly lex all legal Ruby 1.8 code that I've been able to 
find on my Debian system. It can also handle (most of) my catalog of nasty 
test cases (in testdata/p.rb) (see below for known problems). At this point, 
new bugs are almost exclusively found by my home-grown test code, rather 
than ruby code gathered 'from the wild'. There are a number of issues I know 
about and plan to fix, but it seems that Ruby coders don't write code complex 
enough to trigger them very often. Although incomplete, RubyLexer can 
correctly distinguish these ambiguous uses of the following operator and 
keywords, depending on context:
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
context not really preserved when entering or leaving string inclusions. this causes
a number or problems. local variables are ok now, but here document headers started
in a string inclusion with the body outside will be a problem. (0.8)
string tokenization sometimes a little different from ruby around newlines
  (htree/template.rb) (0.8)
string contents might not be correctly translated in a few cases (0.8?)
symbols which contain string interpolations are flattened into one token. eg :"foo#{bar}" (0.8)
'\r' whitespace sometimes seen in dos-formatted output.. shouldn't be (eg pre.rb) (0.7)
windows newline in source is likely to cause problems in obscure cases (need test case)
unterminated =begin is not an error (0.8)
ruby 1.9 completely unsupported (0.9)
character sets other than ascii are not supported at all (1.0)
regression test currently shows 14 errors with differences in exact token ordering
-around string inclusions. these errors are much less serious than they seem.
offset of AssignmentRhsListEndToken appears to be off by 1

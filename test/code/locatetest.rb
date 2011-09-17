=begin legal crap
    rubylexer - a ruby lexer written in ruby
    Copyright (C) 2004,2005,2008, 2011  Caleb Clausen

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
=end

require 'test/code/rubylexervsruby'
require 'test/code/strgen'

class RubyLexer
module LocateTest
#ENV['RUBY']||='ruby'
$RUBY=ENV['RUBY']||'ruby'
skip_til=ENV['SKIP_TIL']
#test $RUBY || export RUBY=ruby

#$RUBYLEXERVSRUBY="#$RUBY test/code/rubylexervsruby.rb"

RUBY_VERSION[/^1\.[0-7]\./] and raise 'need ruby>= 1.8'



#if RUBY_VERSION --version|grep '^ruby 1\.6'; then
#  echo 'error: need ruby 1.8'; exit
#fi


RLROOT= (File.dirname $0)+'/../..'
#cd `dirname -- $0`

=begin if locate fails, we should use the algorithm from this sh code

#also look in bin and lib directories
file -L `echo $PATH":/sbin:/usr/sbin"|tr : "\n"|sort -u|xargs -i echo "{}/*"`| \
 grep "ruby[^:]*script"|cut -d: -f1 > test/results/rubyexelibs

ruby -e 'print ($:.sort.uniq+[""]).join"\n"'|xargs -i ls "{}/*.rb" >> test/results/rubyexelibs

   for i in `cat test/results/rubyexelibs`; do
      $RUBYLEXERVSRUBY $i;
   done

=end

bindirs=ENV['PATH'].split(':')+['/sbin','/usr/sbin']


puts "hack hack hack: absolute path in ruby test file list"
RUBYBINS= 
bindirs.map{|dir| Dir[dir+"/*"].select{|prog| 
  line1=File.open(prog){|f| f.readline} rescue next
  %r{\A#!([^\s]*/env )?[^\s]*/j?ruby(?:1\.[6789])(?:\s|\n)}===line1
}}.flatten
TEST_THESE_FIRST=
%w[
   
   
   
   
   
   
   
   
   
   
   
   
   /home/caleb/sandbox/jewels/xrefresh-server-0.1.0/lib/xrefresh-server.rb
   /home/caleb/sandbox/jewels/shattered-0.7.0/test/acceptance/lib/mesh_test.rb
   /home/caleb/sandbox/jewels/rutils-0.2.3/lib/countries/countries.rb
   /home/caleb/sandbox/jewels/ruport-1.6.1/examples/trac_ticket_status.rb
   /home/caleb/sandbox/jewels/rubysdl-2.0.1/extconf.rb
   /home/caleb/sandbox/jewels/rubysdl-1.1.0/extconf.rb
   /home/caleb/sandbox/jewels/ruby-msg-1.3.1/lib/msg/rtf.rb
   /home/caleb/sandbox/jewels/ruby-mediawiki-0.1/apps/iso_639_leecher.rb
   /home/caleb/sandbox/jewels/ruby-finance-0.2.2/lib/finance/quote/yahoo/australia.rb
   /home/caleb/sandbox/jewels/roby-0.7.2/test/test_task.rb
   /home/caleb/sandbox/jewels/reve-0.0.94/test/test_reve.rb
   /home/caleb/sandbox/jewels/remote_api-0.2.1/test/spec_test.rb
   /home/caleb/sandbox/jewels/rbrainz-0.4.1/examples/getartist.rb
   /home/caleb/sandbox/jewels/rbrainz-0.4.1/examples/getlabel.rb
   /home/caleb/sandbox/jewels/rbrainz-0.4.1/examples/gettrack.rb
   /home/caleb/sandbox/jewels/railscart-0.0.4/starter_app/vendor/plugins/engines/init.rb
   /home/caleb/sandbox/jewels/ok-extensions-1.0.15/test/extensions/test_object.rb
   /home/caleb/sandbox/jewels/oai-0.0.8/lib/oai/harvester/logging.rb
   /home/caleb/sandbox/jewels/oai-0.0.8/examples/providers/dublin_core.rb
   /home/caleb/sandbox/jewels/erubis-2.6.2/test/assert-text-equal.rbc
   /home/caleb/sandbox/jewels/erubis-2.6.2/test/test-engines.rbc
   /home/caleb/sandbox/jewels/erubis-2.6.2/test/test-erubis.rbc
   /home/caleb/sandbox/jewels/erubis-2.6.2/test/test-users-guide.rbc
   /home/caleb/sandbox/jewels/erubis-2.6.2/test/test.rbc
   /home/caleb/sandbox/jewels/erubis-2.6.2/test/testutil.rbc
   /home/caleb/sandbox/jewels/fb-0.5.5/test/CursorTestCases.rb
   /home/caleb/sandbox/jewels/flickraw-0.4.5/examples/auth.rb
   /home/caleb/sandbox/jewels/flickraw-0.4.5/examples/upload.rb
   /home/caleb/sandbox/jewels/flickraw-0.4.5/test/test.rb
   /home/caleb/sandbox/jewels/fox-tool-0.10.0-preview/fox-tool/examples/input.rbin
   /home/caleb/sandbox/jewels/fox-tool-0.10.0-preview/fox-tool/examples/cvs/Base/print.rbin
   /home/caleb/sandbox/jewels/foxGUIb_1.0.0/foxguib_1.0.0/foxguib/src/gui/_guib_genruby.rbin
   /home/caleb/sandbox/jewels/hpricot_scrub-0.3.2/test/scrubber_data.rb
   /home/caleb/sandbox/jewels/htmltools-1.10/test/tc_stacking-parser.rb
   /home/caleb/sandbox/jewels/ludy-0.1.13/test/deprecated/ts_ludy.rb
   /home/caleb/sandbox/jewels/menu_helper-0.0.5/test/unit/menu_test.rb
   /home/caleb/sandbox/jewels/mod_spox-0.0.5/data/mod_spox/extras/PhpCli.rb
   /home/caleb/sandbox/jewels/motiro-0.6.11/app/core/wiki_page_not_found.rb
   /home/caleb/sandbox/jewels/motiro-0.6.11/vendor/plugins/globalize/generators/globalize/templates/migration.rb.gz

]+[
  "/home/caleb/sandbox/jewels/core_ex-0.6.6.3/lib/core_ex/numeric.rb",
  "/home/caleb/sandbox/jewels/cerberus-0.3.6/test/bjam_builder_test.rb",
  "/home/caleb/sandbox/jewels/cerberus-0.3.6/test/maven2_builer_test.rb",
  "/home/caleb/sandbox/jewels/buildr-1.3.1.1/lib/buildr/java/groovyc.rb",
  "/home/caleb/sandbox/jewels/adhearsion-0.7.7/apps/default/helpers/micromenus.rb",
  "/home/caleb/rubies/ruby-1.8.7/instruby.rb",
  "/home/caleb/sandbox/jewels/RuCodeGen-0.3.1/lib/rucodegen/value_incapsulator.rb",

  "/home/caleb/sandbox/jewels/Wiki2Go-1.17.3/test/TestWiki2GoServlet.rb",
  "/home/caleb/rubies/ruby-1.8.7/test/rss/test_parser_atom_entry.rb",
  "/home/caleb/sandbox/jewels/active_form-0.0.8/test/elements/test_base_element.rb",
  "/home/caleb/sandbox/jewels/dohruby-0.2.1/bin/create_database.rb",
  "/home/caleb/sandbox/jewels/depager-0.2.2/examples/c89/c89.tab.rb",

  "/home/caleb/sandbox/jewels/samizdat-0.6.1/samizdat/lib/samizdat/storage.rb",
  "/home/caleb/sandbox/jewels/math3d-0.04/tests/make_tests.rb",
  "/home/caleb/sandbox/jewels/QuickBaseClient.rb/quickbasecontactsappbuilder.rb",
  "/home/caleb/sandbox/jewels/QuickBaseClient.rb/quickbaseclient.rb",
  "/home/caleb/sandbox/jewels/ruby-ivy_0.1.0/ruby-ivy/examples/._000-IVYTranslater.rb",
  "/home/caleb/sandbox/jewels/ruby-ivy_0.1.0/ruby-ivy/examples/._002-ApplicationList.rb",
  "/home/caleb/sandbox/jewels/ruby-ivy_0.1.0/ruby-ivy/examples/._001-UnBind.rb",
  "/home/caleb/sandbox/jewels/ruby-ivy_0.1.0/ruby-ivy/._extconf.rb",
  "/home/caleb/sandbox/jewels/smf-0.15.10/sample/virtual-samp.rb",
  "/home/caleb/sandbox/jewels/syntax/syntax.rb",
  "/home/caleb/sandbox/jewels/rex-1.0rc1/rex/packages/rex/test/rex-20060511.rb",
  "/home/caleb/sandbox/jewels/rex-1.0rc1/rex/packages/rex/test/rex-20060125.rb",
#  "/home/caleb/sandbox/jewels/japanese-zipcodes-0.0.20080227/lib/japanese/zipcodes.rb", #huge!!!!!
]
RUBYLIST=TEST_THESE_FIRST+RUBYBINS+
[RLROOT+"/test/data/p.rb", 
  *Dir["test/data/*.rb"]+
  `(
    locate /inline.rb /tk.rb;
    locate examples/examples_test.rb;
    locate .rb; 
    locate rakefile; locate Rakefile; locate RAKEFILE; 
  )|egrep -v '(/test/(results|data)/|.broken$)'`.
    split("\n").reject{|i| %r(japanese/zipcodes\.rb\Z)===i }
]
RUBYLIST.uniq!
if skip_til
  skip_til=RUBYLIST.index(skip_til)
  skip_til or fail "SKIP_TIL not found in list of rubies"
  RUBYLIST.slice! 0...skip_til
end
def self.main
for i in RUBYLIST do
#  system $RUBYLEXERVSRUBY, i
  #hmm, rubylexervsruby needs to be upgraded to not regard an output
  #consisting entirely of warnings as a failure.
  #if no 'warning' (in any capitalization) for 4 or more lines
  begin
#  puts File.readlines("/proc/#{$$}/status").grep(/^VmSize:\s/)
  File.exist? i or next
  RubyLexerVsRuby.rubylexervsruby i,nil,nil,true #or puts "syntax error in #{i}"
  rescue Interrupt; raise
  rescue Exception=>e
    puts "error in: "+i
    puts e
    puts e.backtrace.map{|s| "    from: "+s}.join("\n")
  end
end
end
#for i in test/data/p.rb `(locate /tk.rb;locate examples/examples_test.rb;#locate .rb; locate rakefile; locate Rakefile; locate RAKEFILE)|egrep -v '/#test/results/'`; do
#  $RUBYLEXERVSRUBY $i
#done
end
end

RubyLexer::LocateTest.main if $0==__FILE__

#!/bin/sh
#    rubylexer - a ruby lexer written in ruby
#    Copyright (C) 2004,2005  Caleb Clausen
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public
#    License as published by the Free Software Foundation; either
#    version 2.1 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public
#    License along with this library; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA


#export DEBUG=-rdebug


#export RUBYLEXERVSRUBY=testcode/rubylexervsruby.sh
test $RUBY || export RUBY=ruby
export RUBYLEXERVSRUBY="$RUBY testcode/rubylexervsruby.rb"

#ruma driver tests
#(disabled for now)
#./rumadriver.rb testdata/foobar.rm rulexer.rb
#exit

$RUBY -d $DEBUG testcode/tokentest.rb assert.rb | diff -ub testdata/tokentest.assert.rb.can -
#$RUBY -d $DEBUG testcode/tokentest.rb testdata/a | diff -ub testdata/tokentest.a.can -
$RUBYLEXERVSRUBY testdata/p.rb
$RUBYLEXERVSRUBY testdata/w.rb
$RUBYLEXERVSRUBY testdata/g.rb


$RUBYLEXERVSRUBY testdata/regtest.rb

$RUBYLEXERVSRUBY   testdata/untitled1.rb

$RUBYLEXERVSRUBY /usr/lib/ruby/1.8/htree/template.rb #small diff, no semantic change
#set -e

$RUBYLEXERVSRUBY testdata/_usr_share_doc_libtcltk-ruby1.8_exmaples_sample_sample2.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.8_image_size.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.8_rexml_dtd_entitydecl.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.8_rexml_dtd_notationdecl.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.8_rexml_xpath.rb
#exit
#nil char at eof:
$RUBYLEXERVSRUBY /usr/share/freeride/freebase/lib/freebase/databus.rb
$RUBYLEXERVSRUBY /usr/share/freeride/plugins/rubyide_fox_gui/editpane.rb

$RUBYLEXERVSRUBY /usr/share/freeride/plugins/rubyide_tools_fox_source_browser/basic_source_browser.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.8_tk.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.6_cgi.rb
$RUBYLEXERVSRUBY /usr/share/freeride/plugins/rubyide_fox_gui/appframe.rb
$RUBYLEXERVSRUBY testdata/_usr_share_doc_ruby1.8-examples_examples_test.rb
$RUBYLEXERVSRUBY /usr/share/freeride/plugins/rubyide_tools_source_parser/basic_parser.rb
$RUBYLEXERVSRUBY /usr/share/freeride/plugins/rubyide_commands/core_commands.rb
$RUBYLEXERVSRUBY /usr/share/freeride/plugins/rubyide_fox_gui/fxscintilla/scintilla.rb
$RUBYLEXERVSRUBY /usr/lib/ruby/1.8/rdoc/parsers/parse_c.rb
$RUBYLEXERVSRUBY /usr/share/doc/rdtool/examples/rdswap.rb.gz
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.8_cgi.rb
$RUBYLEXERVSRUBY domain.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.8_optparse.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.8_resolv.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.6_resolv.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.8_racc_output.rb
$RUBYLEXERVSRUBY /usr/share/freeride/plugins/rubyide_commands/key_manager.rb
$RUBYLEXERVSRUBY /usr/lib/ruby/1.8/progressbar.rb
$RUBYLEXERVSRUBY /usr/lib/ruby/1.8/yaml/rubytypes.rb
$RUBYLEXERVSRUBY /usr/share/freeride/plugins/rubyide_fox_gui/fxscintilla/ruby_colourize.rb
$RUBYLEXERVSRUBY /usr/share/freeride/plugins/rubyide_fox_gui/outputpane.rb
$RUBYLEXERVSRUBY /usr/lib/ruby/1.8/yaml/basenode.rb
$RUBYLEXERVSRUBY /usr/share/freeride/plugins/rubyide_fox_gui/fxscintilla/ruby_autoindent.rb
$RUBYLEXERVSRUBY /usr/share/doc/libxtemplate-ruby1.8/examples/sample33.rb
$RUBYLEXERVSRUBY /usr/lib/ruby/1.8/rmail/header.rb
$RUBYLEXERVSRUBY /usr/share/doc/libxtemplate-ruby1.8/examples/sample34.rb
$RUBYLEXERVSRUBY /usr/lib/ruby/1.8/runit/testsuite.rb
$RUBYLEXERVSRUBY /usr/lib/ruby/1.8/zip/zip.rb
$RUBYLEXERVSRUBY /usr/lib/ruby/1.8/html/template.rb

#exit













$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.6_xmlrpc_utils.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.8_rubyunit.rb

$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.6_parsedate.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.8_date_format.rb

$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.8_tkcanvas.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.8_tkdialog.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.8_net_imap.rb

$RUBYLEXERVSRUBY testdata/_usr_share_doc_libtk-ruby1.8_exmaples_tkmultilistbox.rb
$RUBYLEXERVSRUBY testdata/_usr_share_doc_ruby-examples_examples_mine.rb
$RUBYLEXERVSRUBY testdata/_usr_share_doc_ruby-examples_examples_observ.rb
$RUBYLEXERVSRUBY testdata/_usr_share_doc_ruby1.8-examples_examples_mine.rb
$RUBYLEXERVSRUBY testdata/_usr_share_doc_ruby1.8-examples_examples_observ.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.6_aswiki_util.rb
$RUBYLEXERVSRUBY testdata/_usr_share_doc_libopengl-ruby_examples_clip.rb


$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.6_amrita_parts.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.6_cgi_session.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.6_complex.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.6_csv.rb
$RUBYLEXERVSRUBY testdata/_usr_share_doc_libglade-ruby_examples_test.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.6_amrita_ams.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.6_amrita_format.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.6_amrita_node.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.6_amrita_tag.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.6_amstd_version.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.8_webrick_httputils.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.6_net_imap.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.8_resolv-replace.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.8_irb_ruby-lex.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.6_date.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.8_racc_raccp.rb

$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.8_rd_rdinlineparser.tab.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.8_rd_rdblockparser.tab.rb


$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/texturesurf.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libncurses-ruby1.8/examples/tclock.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgtkglext1-ruby/examples/simple-mixed.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/surface.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/tess.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/lines.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libamrita-ruby1.6/examples/bbs/bbs.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgtk2-ruby/examples/gtk-demo/menus.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/feedback.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/wrap.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgtk2-ruby/examples/gtk-demo/main.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/pickdepth.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgtk2-ruby/examples/gtk-demo/tree_store.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/teaambient.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libart2-ruby/examples/testlibart2.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgnomecanvas2-ruby/examples/canvas-primitives.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgtk2-ruby/examples/gtk-demo/images.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libamrita-ruby1.6/examples/bbs/test/testbbs.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgnomecanvas2-ruby/examples/canvas-curve.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/texgen.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgtk2-ruby/examples/gtk-demo/stock_browser.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libncurses-ruby1.8/examples/example.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgtk2-ruby/examples/gtk-demo/pixbufs.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgtk2-ruby/examples/gtk-demo/list_store.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgda2-ruby/examples/sample.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libamrita-ruby1.6/examples/bbs/model.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/teapots.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgstreamer0.6-ruby/examples/media-type2.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgnome2-ruby/examples/test-gnome/app-helper.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgtk2-ruby/examples/testgtk/spinbutton.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/select.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/quadric.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgtk2-ruby/examples/gtk-demo/drawingarea.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/accpersp.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/dof.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgtk2-ruby/examples/testgtk/cursors.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/accanti.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgtk2-ruby/examples/testgtk/dnd.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/plane.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libnet-acl-ruby1.6/examples/acltest.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/aapoly.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgtk2-ruby/examples/gtk-demo/changedisplay.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgnome2-ruby/examples/gnome-config.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/jitter.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/image.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/font.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgtkglext1-ruby/examples/gtkglut.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgstreamer0.6-ruby/examples/gst-inspect.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/fog.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgtkglext1-ruby/examples/font.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/alpha3D.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/alpha.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgtk2-ruby/examples/testgtk/testgtk.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgnomecanvas2-ruby/examples/canvas-arrowhead.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/aargb.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgtkglext1-ruby/examples/simple.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgnome2-ruby/examples/gnome-app-helper.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgtk2-ruby/examples/gtk-demo/textview.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/stroke.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgtk2-ruby/examples/testgtk/progressbar.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/colormat.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgtkglext1-ruby/examples/share-lists.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgtk2-ruby/examples/testgtk/liststore.rb.gz

$RUBYLEXERVSRUBY /usr/share/freeride/plugins/rubyide_fox_gui/fxscintilla/ruby_properties.rb
$RUBYLEXERVSRUBY /usr/share/doc/rubymagick/examples/demo.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libopengl-ruby/examples/texbind.rb.gz
$RUBYLEXERVSRUBY /usr/share/doc/libgnome2-ruby/examples/test-gnome/font-picker.rb.gz

echo 'skipping some cmds:'
echo 'these generate split-line warnings (low prio issue for now)'
cat <<end
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.6_optparse.rb
$RUBYLEXERVSRUBY testdata/_usr_share_doc_libxmlrpc-ruby1.6_examples_perf_async.rb
$RUBYLEXERVSRUBY testdata/_usr_share_doc_libdrb-ruby1.6_examples_dlogd.rb
$RUBYLEXERVSRUBY testdata/_usr_bin_dpkg-checkdeps.rb
$RUBYLEXERVSRUBY testdata/_usr_share_doc_libgtk-ruby_examples_testgtk_ctree.rb
$RUBYLEXERVSRUBY testdata/_usr_share_doc_ruby-examples_examples_cal.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.8_rd_rd2man-lib.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.6_xmltree.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.6_parsearg.rb
$RUBYLEXERVSRUBY testdata/_usr_lib_ruby_1.6_tracer.rb
end

#oops, looks like this one's missing an end
#$RUBYLEXERVSRUBY /usr/share/freeride/freebase/plugins/raa_xmlrpc4r/rpcd.rb

#not legal in ruby 1.8
#$RUBYLEXERVSRUBY /usr/share/doc/libtcltk-ruby1.6/exmaples/sample/sample1.rb

#these 3 aren't legal ruby:
#$RUBYLEXERVSRUBY /usr/share/doc/libdb4.1-ruby1.8/bdb.rb.gz
#$RUBYLEXERVSRUBY /usr/share/doc/libdb2-ruby1.8/bdb.rb.gz
#$RUBYLEXERVSRUBY /usr/share/doc/libdb3-ruby1.8/bdb.rb.gz

#not even vaguely legal ruby:
#$RUBYLEXERVSRUBY /usr/share/doc/libdebconf-client-ruby/examples/test.rb.templates.ja
#$RUBYLEXERVSRUBY /usr/share/doc/libdebconf-client-ruby/examples/test.rb.templates.in
#$RUBYLEXERVSRUBY /usr/share/doc/libdebconf-client-ruby/examples/test.rb.templates


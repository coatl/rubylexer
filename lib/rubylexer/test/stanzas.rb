def x; yield end #this must be first!!!!
#the purpose of x{...} is to prevent the enclosed code from
#modifying the list of known local variables. it may be omitted
#in cases where it is known that no local vars are defined.

module SR
def SelfReferencing
#old name alias
end
def SelfReferencing #old name alias
end
def SelfReferencing#old name alias
end
def SelfReferencing;end#old name alias
end

p <<Class
  zzzz
Class

p(String <<Class)
sgsdfgf
  Class
Class

def foo; end
undef
foo

module Defined_p_syntax_tests
  def self.defined?(foo) :baz end  #should be methname
  def defined?(foo) :bar end  #should be methname
  def ameth
    p(defined? 44)  #should be keyword
    p(self.defined? 44) #should be methname
  end
end

proc{
p /$/  #regexp
p /=$/ #operator
p /$/  #operator
}

proc{
p %=b=
2
p %(1)
}

proc{
p *=5
p %(1)
}

proc{
p &nil
p &=1
p %(1)
}



p <<p
\
p
p

p <<'p'
\
p
p

p <<p
\n\t\r\v\\
p

p <<'p'
\n\t\r\v\\
p

p <<'p'
\n\t\r\v\
p
p

p <<p
\
sdfgd
p


p <<END
dfgdfg
END

p <<'END'
hgjfg
END

x{
  a,b,c,(d,e)=1,2,3,[4,5]
  p a %(4)
  p c %(4)
  p d %(4)
  p e %(4)
}

def printem___1 a
   a
end

class F0000; end
def F0000; end

x{
  f0000=1
  def f0000; end
}

def printem__1 a
   p(a +77)
end

def printem_1 a,b
   p(a +77)
   p(b +77)
end

def printem1 a,b,c
   p(a +77)
   p(b +77)
   p(c +77)
end

def printem10 a,b,c,d,e,f
   p(a +77)
   p(b +77)
   p(c +77)
   p(d +77)
   p(e +77)
   p(f +77)
end

def printem100 a,b,c,d,e,f,*g,&h
   p(a +77)
   p(b +77)
   p(c +77)
   p(d +77)
   p(e +77)
   p(f +77)
   p(g +77)
   p(h +77)
end

ddd="ddd"

#@@ddd=@ddd=$ddd=nil
def DDD;end
def ddd2; "asdAds" end
def (DDD()).foofarendle;end
def Integer.foofarendle;end
def @@ddd.foofarendle;  33;end
def @ddd.foofarendle;  33;end
def $ddd.foofarendle;  33;end
def ddd.foofarendle;  33;end
def ddd2.foofarendle;  33;end
def (ddd).foofarendle2; end
def (ddd()).foofarendle2; end
def (ddd2).foofarendle;end
def ddd2.foofarendle;end

p(<<-jjj \
 dsfgdf
 jjj
 )

p(<<-jjj \
 dsfgdf
 jjj
 +"dfsdfs"
 )

p(<<-jjj
 dsfgdf
 jjj
 )

p(<<-jjj +
 dsfgdf
 jjj
 "dfsdfs"
 )

case 1
when *[2]: p 1
else p 2
end

x{
  foo bar=>baz
  bar %(1)
}

def foo1
  p (1..10).method(:each)    #implicit parens around the whole thing
end

def foo2()
  p((1..10).method(:each))  #explicitly parenthesized... no implicit parens needed
end

def foo3()
  p (1..10).method(:each)   #implicit parens around the whole thing
end

p proc{|
a,b,(c,d,),e|
        p a %(1)
        p b %(2)
        p c %(3)
        p d %(4)
        p e %(5)
[ a,b,c,d,e]}.call(1,2,[3,4],5)

def ggg(x=nil) p x;9 end
 (ggg / 1)


module Y19  #limit lvar scope
  a,b,c,(d,e)=1,2,3,[4,5]
  p a %(4)
  p c %(4)
  p d %(4)
  p e %(4)
  a=[1,2,3,4,5]
  def self.g(x=nil); 3 end
  def a.g=(x) p x end
  g = 5
  self.g = 55
  class<<a
    def bb=(x) p :bb=, x end
  end
  A=a
  class<<self
  def aa; :aa end
  def bb(arg=nil); p :bb; A end
  alias bbb bb
  def m; self end
  def n; self end
  def +(other) self end
  def kk; nil end
  def kk=(foo); nil end
  end
  proc{|a[4]|}.call 6
  proc{|a[b]|}.call 7
  proc{|a.bb| bb %(9) }.call 9
  proc{|a[f]| f %(9)  }.call 8
  proc{|bb(aa).bb| aa %(10) }.call 10
  proc{|bbb(aa).bb| bbb %(11) }.call 11
  proc{|t,u,(v,w,x),(y,),z|
    t %(12)
    u %(12)
    v %(12)
    w %(12)
    x %(12)
    y %(12)
    z %(12)
  }.call(1,2,[3,4,5],[6],7)
  proc{|(m).kk,(m+n).kk|
    m %(13)
    n %(13)
    kk %(13)
  }.call(13,14)
  proc{|a.g| g %(9)}
  p a
end

x {
  class<<self
   alias q p
   alias r p
   alias s p
  end
  p(q,r,s)
  q %(1)
  r %(1)
  s %(1)
  p (q,r,s)
  q %(1)
  r %(1)
  s %(1)
}

p true ?
  1 : 2

class String
class Class
end
end

p(String<<Class)
p(String<< Class)
p(String <<Class)
sgsdfgf
  Class
Class
p(String << Class)

p(String<<-Class)
p(String<< -Class)
p(String <<-Class)
sgsdfgf
  Class
Class
p(String <<-Class)
sgsdfgf
Class
  Class
Class
p(String << -Class)

p(String<<- Class)
p(String<< - Class)
p(String <<- Class)
  Class
Class
p(String <<- Class)
Class
  Class
Class
p(String << - Class)



p <<p
sdfsfdf^^^^@@@
p

module M33
  p="var:"
  Q="func:"
  def Q.method_missing(name,*args)
    self+name.to_s+(args.join' ')
  end
  def p.method_missing(name,*args)
    self+name.to_s+(args.join' ')
  end
  def self.p(*a); super; Q end
  @a=1
  $a=2
  p(p~6)
  p(p ~6)
  p(p~ 6)
  p(p ~ 6)
  p(p*11)
  p(p *11)
  p(p* 11)
  p(p * 11)
  p(p&proc{})
  p(p &proc{})
  p(p& proc{})
  p(p & proc{})
  p(p !1)
#  p(p ?1) #compile error, when p is var
  p(p ! 1)
  p(p ? 1 : 6)
  p(p@a)
  p(p @a)
#  p(p@ a)  #wont
#  p(p @ a) #work
  p(p#a
)
  p(p #a
)
  p(p# a
)
  p(p # a
)
  p(p$a)
  p(p $a)
#  p(p$ a)  #wont
#  p(p $ a) #work
  p(p%Q{:foo})
  p(p %Q{:foo})
  p(p% Q{:foo})
  p(p % Q{:foo})
  p(p^6)
  p(p ^6)
  p(p^ 6)
  p(p ^ 6)
  p(p&7)
  p(p &proc{7})
  p(p& 7)
  p(p & 7)
  p(p(2))
  p(p (2))
  p(p( 2))
  p(p ( 2))
  p(p(p))
  p(p())
  p(p (p))
  p(p ())
  p(p ( p))
  p(p ( ))
  p(p( p))
  p(p( ))
  p(p)
  p((p))
  p(p )
  p((p ))
  p((p p))
  p((p p,p))
  p((p p))
  p((p p,p))
  p(p-0)
  p(p -0)
  p(p- 0)
  p(p - 0)
  p(p+9)
  p(p +9)
  p(p+ 9)
  p(p + 9)
  p(p[1])
  p(p [1])
  p(p[ 1])
  p(p [ 1])
  p(p{1})
  p(p {1})
  p(p{ 1})
  p(p { 1})
  p(p/1)
  p(p /22)
  p(p/ 1)
  p(p / 22)
  p(p._)
  p(p ._)
  p(p. _)
  p(p . _)
  p(false ? p:f)
  p(false ? p :f)
  p(false ? p: f)
  p(false ? p : f)
  p((p;1))
  p((p ;1))
  p((p; 1))
  p((p ; 1))
  p(p<1)
  p(p <1)
  p(p< 1)
  p(p < 1)
  p(p<<1)
  p(p <<1)
  p(p<< 1)
  p(p << 1)
  p(p'j')
  p(p 'j')
  p(p' j')
  p(p ' j')
  p(p"k")
  p(p "k")
  p(p" k")
  p(p " k")
  p(p|4)
  p(p |4)
  p(p| 4)
  p(p | 4)
  p(p>2)
  p(p >2)
  p(p> 2)
  p(p > 2)
end

module M34
  p(p~6)
  p(p ~6)
  p(p~ 6)
  p(p ~ 6)
  p(p*[1])
  p(p *[1])
  p(p* [1])
  p(p * [1])
  p(p&proc{})
  p(p &proc{})
  p(p& proc{})
  p(p & proc{})
  p(p !1)
  p(p ?1)
  p(p ! 1)
  p(p ? 1 : 6)
  p(p@a)
  p(p @a)
#  p(p@ a)  #wont
#  p(p @ a) #work
  p(p#a
)
  p(p #a
)
  p(p# a
)
  p(p # a
)
  p(p$a)
  p(p $a)
#  p(p$ a)  #wont
#  p(p $ a) #work
  p(p%Q{:foo})
  p(p %Q{:foo})
  p(p% Q{:foo})
  p(p % Q{:foo})
  p(p^6)
  p(p^ 6)
  p(p ^ 6)
  p(p&7)
  p(p &proc{7})
  p(p& 7)
  p(p & 7)
  p(p(2))
  p(p (2))
  p(p( 2))
  p(p ( 2))
  p(p(p))
  p(p())
  p(p (p))
  p(p ())
  p(p ( p))
  p(p ( ))
  p(p( p))
  p(p( ))
  p(p)
  p((p))
  p(p )
  p((p ))
  p((p p))
  p((p p,p))
  p((p p))
  p((p p,p))
  p(p-0)
  p(p -1)
  p(p- 0)
  p(p - 0)
  p(p+9)
  p(p +9)
  p(p+ 9)
  p(p + 9)
  p(p[1])
  p(p [1])
  p(p[ 1])
  p(p [ 1])
  p(p{1})
  p(p {1})
  p(p{ 1})
  p(p { 1})
  p(p/1)
  p(p /22/)
  p(p/ 1)
  p(p / 22)
  p(p._)
  p(p ._)
  p(p. _)
  p(p . _)
  p(p:f)
  p(p :f)
  p(false ? p: f)
  p(false ? p : f)
  p((p;1))
  p((p ;1))
  p((p; 1))
  p((p ; 1))
  p(p<1)
  p(p <1)
  p(p< 1)
  p(p < 1)
  p(p<<1)
  p(p <<1)
foobar
1
  p(p<< 1)
  p(p << 1)
  p(p'j')
  p(p 'j')
  p(p' j')
  p(p ' j')
  p(p"k")
  p(p "k")
  p(p" k")
  p(p " k")
  p(p|4)
  p(p |4)
  p(p| 4)
  p(p | 4)
  p(p>2)
  p(p >2)
  p(p> 2)
  p(p > 2)
end

x{
  def bob(x) x end
  p(bob %(22))
  for bob in [100] do p(bob %(22)) end
  p(bob %(22))
}

x{
  def %(n) to_s+"%#{n}" end
  def bill(x) x end
  p(bill %(22))
  begin sdjkfsjkdfsd; rescue Object => bill; p(bill %(22)) end  
  p(bill %(22))
  undef %
}

class Fixnum
  public :`
  def `(s)
    print "bq: #{s}\n"
  end
end
69.`('what a world')
79::`('what a word')

x{
  a=5
  p p +5
  p a +5
}

class Foou
 public
 def [] x=-100,&y; p x; 100 end
end

p Foou.new.[] <<9    #value
foobar
9

x{
  a0=9
  p Foou.new.[]a0      #value
  p Foou.new.[] a0     #value
}

x{
  a=b=c=0
  a ? b:c
  a ?b:c
  p(a ? b:c)
  p(a ?b:c)
  p(a ?:r:c)
  p(a ? :r:c)
}

x{
  h={}
  h.default=:foo
  p def h.default= v; p @v=v;v end
  p def (h).default= v; p @v=v;v end
  p def (h="foobar").default= v; p @v=v;v end
  p h
  p h.default=:b
}

x do
x, (*y) = [:x, :y, :z]
p x
p y
x, *y = [:x, :y, :z]
p x
p y
x, * = [:x, :y, :z]
p x
end

class Foop
  def Foop.bar a,b
    p a,b
  end
end
Foop.bar 1,2
Foop::bar 3,4


class Foop
  def Foop::baz a,b
    p :baz,a,b
  end
end
Foop.baz 5,6
Foop::baz 7,8

x{
      without_creating=widgetname=nil
      if without_creating && !widgetname #foo
        fail ArgumentError,
             "if set 'without_creating' to true, need to define 'widgetname'"
      end
}

x{
#class, module, and def should temporarily hide local variables
def mopsdfjskdf arg; arg*2 end
mopsdfjskdf=5
 class C
 p mopsdfjskdf %(3)    #calls method
 end
module M
 p mopsdfjskdf %(4)    #calls method
end
 def d
 p mopsdfjskdf %(5)    #calls method
 end
p d
p mopsdfjskdf %(6)     #reads variable
p proc{mopsdfjskdf %(7)}[] #reads variable
}

#multiple assignment test
x {
  a,b,c,d,e,f,g,h,i,j,k=1,2,3,4,5,6,7,8,9,10,11
  p(b %(c))
  p(a %(c))
  p(k %(c))
  p(p %(c))
}

p "#{<<kekerz}#{"foob"
zimpler
kekerz
}"

aaa=<<whatnot; p "#{'uh,yeah'
gonna take it down, to the nitty-grit
gonna tell you mother-fuckers why you ain't shit
cause suckers like you just make me strong
you been pumpin' that bullshit all day long
whatnot
}"
p aaa

#test variable creation in string inclusion
#currently broken because string inclusions
#are lexed by a separate lexer!
proc {
  p "jentawz: #{baz=200}"
  p( baz %(9))
}.call

#scope of local variables always includes the here document
#body if it includes the head
p %w[well, whaddaya know].map{|j| <<-END }
#{j #previous j should be local var, not method
}45634543
END

p "#{<<foobar3}"
bim
baz
bof
foobar3

x do
  a,b,* = [1,2,3,4,5,6,7,8]
  p a,b
  a,b, = [1,2,3,4,5,6,7,8]
  p a,b
  a,b = [1,2,3,4,5,6,7,8]
  p a,b
  a,*b = [1,2,3,4,5,6,7,8]
  p a,b
  a,b,*c=[1,2,3,4,5,6,7,8]
  a,b,* c=[1,2,3,4,5,6,7,8]
end

x {
  h={:a=>(foo=100)}
  p( foo %(5))
}

def foo(a=<<a,b=<<b,c=<<c)
jfksdkjf
dkljjkf
a
kdljfjkdg
dfglkdfkgjdf
dkf
b
lkdffdjksadhf
sdflkdjgsfdkjgsdg
dsfg;lkdflisgffd
g
c
   a+b+c
end


class AA; class BB; class CC
FFOO=1
end end end
p AA::BB::CC::FFOO

x do
 method_src = c.compile(template, (HtmlCompiler::AnyData.new)).join("\n") +
    "\n# generated by PartsTemplate::compile_partstemplate at #{Time.new}\n"
 rescu -1
end

  p('rb_out', 'args', <<-'EOL')
    regsub -all {!} $args {\\!} args
    regsub -all "{" $args "\\{" args
    if {[set st [catch {ruby [format "TkCore.callback %%Q!%s!" $args]} ret]] != 0} {
        return -code $st $ret
    } {
        return $ret
    }
  EOL


def add(*args)
   self.<<(*args)
end


x{
  val=%[13,17,22,"hike", ?\s]
    if val.include? ?\s
      p val.split.collect{|v| (v)}
    end
}

class Hosts
end
class DNS < Hosts
end


def ssssss &block
end

def params_quoted(field_name, default)
  if block_given? then yield field_name else default end
end

x{
  def yy;yield end
  block=proc{p "blah  blah"}
  yy &block
}

p(proc do
   p=123
end.call)

p proc {
   p=123
}.call

p def pppp
   p=123
end

p module Ppp
   p=123
end

p class Pppp < String
   p=123
end

    def _make_regex(str) /([#{Regexp.escape(str)}])/n end
    p _make_regex("8smdf,34rh\#@\#$%$gfm/[]dD")

p "#$a #@b #@@c
d e f
#$a #@b #@@c
"

x do
a='a'
class <<a
  def foobar
     self*101
  end
  alias    eql?    ==
end
p a.foobar
end

p %w[a b c
     d e f]

p %w[a b c\n
     d e f]

     formatter.format_element(element) do
       amrita_expand_and_format1(element, context, formatter)
     end

 ret = <<-END
 @@parts_template = #{template.to_ruby}
 def parts_template
   @@parts_template
 end
 #{c.const_def_src.join("\n")}
 def amrita_expand_and_format(element, context, formatter)
   if element.tagname_symbol == :span and element.attrs.size == 0
     amrita_expand_and_format1(element, context, formatter)
   else
     formatter.format_element(element) do
       amrita_expand_and_format1(element, context, formatter)
     end
   end
 end
 def amrita_expand_and_format1(element, context, formatter)
   #{method_src}
 end
 END

p '
'

p "
"

p %w/
/

p %W/
/

p(/
/)

  p `
  `

p <<stuff+'foobar'.tr('j-l','d-f')
"more stuff"
12345678
the quick brown fox jumped over the lazy dog
stuff

p <<stuff+'foobar'.tr('j-l','d-f')
"more stuff"
12345678
the quick brown fox jumped over the lazy dog
stuff

p <<stuff+'foobar'.tr('j-l','d-f')\
+"more stuff"
12345678
the quick brown fox jumped over the lazy dog
stuff

p <<stuff+'foobar'\
+"more stuff"
12345678
the quick brown fox jumped over the lazy dog
stuff


p <<-BEGIN + <<-END
          def element_downcase(attributes = {})
        BEGIN
          end
        END

p <<ggg; def
kleegarts() p 'kkkkkkk' end
dfgdgfdf
ggg
koomblatz!() p 'jdkfsk' end
koomblatz!

p( <<end )
nine time nine men have stood untold.
end

=begin
=end

p <<"..end .."
cbkvjb
vb;lkxcvkbxc
vxlc;kblxckvb
xcvblcvb
..end ..

p <<a
dkflg
flk
a

label='label';tab=[1,2,3]
      p <<S
#{label} = arr = Array.new(#{tab.size}, nil)
str = a = i = nil
idx = 0
clist.each do |str|
  str.split(',', -1).each do |i|
    arr[idx] = i.to_i unless i.empty?
    idx += 1
  end
end
S


def printem1 a,b,c
   p(a +77)
   p(b +77)
   p(c +77)
end

def foobar() end
def foobar2
end

def printem0(a)
   p(a +77)
end

def printem a,b,c
   p a;p b;p c
   p(a +77)
   p(b %(0.123))
end
printem 1,2,3

x do
  a=1
  p(a +77)
  def hhh(a=(1+2)) a end
end

END {
  p "bye-bye"
}


p <<here
where?
here

p <<-what
     ? that's
  what

x{
for i in if false
foob12345; else [44,55,66,77,88] end do p i**Math.sqrt(i) end
}

x{
for i in \
[44,55,66,77,88] do p i**Math.sqrt(i) end
}

x{
for i in if
false then foob12345; else [44,55,66,77,88] end do p i**Math.sqrt(i) end
}

x{
for i in if false then
foob12345; else [44,55,66,77,88] end do p i**Math.sqrt(i) end
}

x{
c=j=0
until while j<10 do j+=1 end.nil? do p 'pppppppppp' end
}

x{
for i in if false then foob12345;
else [44,55,66,77,88] end do p i**Math.sqrt(i) end
}

x{
for i in if false then foob12345; else
[44,55,66,77,88] end do p i**Math.sqrt(i) end
}

x{
for i in (c;
[44,55,66,77,88]) do p i**Math.sqrt(i) end
}

x{
for i in (begin
[44,55,66,77,88] end) do p i**Math.sqrt(i) end
}

x{
for i in if false then foob12345; else
[44,55,66,77,88] end do p i**Math.sqrt(i) end
}

x{
for i in (
[44,55,66,77,88]) do p i**Math.sqrt(i) end
}

x{
for i in (
[44,55,66,77,88]) do p i**Math.sqrt(i) end
}



<<SRC+<<SRC
#{headers}
SRC
#{headers}
SRC


A::
B

A::
b

a::
B

a::
b

        assert_equal 403291461126605635584000000, 26._!
        assert_equal 1, 0._!
        assert_equal 1, 1._!
        assert_equal 24, 4._!


<<here
#{<<there
over there, over there, when its over over there.
there
}
here


[a \
,b]

<<a+<<b
#{c}
345234
a
#{d}
234523452
b

<<a+<<b+\
#{c}
345234
a
#{d}
234523452
b
"sdfsdf"

<<a+<<b+
#{c}
345234
a
#{d}
234523452
b
"sdfsdf"


defined? <<A
sdsdfsdfs
A





\
__END__


__END__

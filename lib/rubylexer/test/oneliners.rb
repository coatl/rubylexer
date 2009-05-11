def x; yield end #this must be first!!!!
#the purpose of x{...} is to prevent the enclosed code from 
#modifying the list of known local variables. it may be omitted
#in cases where it is known that no local vars are defined.

module A::B; end

def (z,*a=0).b; end
def (z,*a=0).b; a %(1) end
def (z,*a=0).b; b %(1) end
def (z,*a=0).b; z %(1) end

p a rescue b
p //e
p //u
p //n
p //s
p 0o

#hash, not block
  def a(b) {} end
  def a.b(c) {} end

  def a.b i; end
  def b i; end  
#uh-oh, implicit parens end before i not after

  return {}.size
  1.return {}.size

  break {}.size
  1.break {}.size

  next {}.size
  1.next {}.size

  raise {}.to_s+"****"
  1.raise {}.to_s+"****"

  throw {}.to_s+"****"
  1.throw {}.to_s+"****"

P ::Class
x{q=1;def q.foo; end}  
#q should be varnametoken, both times
p %(1)

p(p ^6)
p %\hah, backslash as string delimiter\
p %\hah, #{backslash} as string delimiter\
def foo(bar=5,tt=6) end
wwww,eeee=1,2
x{a.b,c.d=1,2}
x{proc{|a.b,c.d|}}

p % foo
p % foo

p(% foo )
p(% foo )

p eval "%\sfoo\s"

p eval "%\tfoo\t"
p eval "%\vfoo\v"
p eval "%\rfoo\r"
p eval "%\nfoo\n"
p eval "%\0foo\0"

p eval "%\r\nfoo\r\n"

#foo
p()
p
p(1,2)     
#these 2 lines should tokenize identically
p (1,2)    
#except for the extra space on this one



p File
#<<'abc123def'
def (is_a?(File::Stat)).foofarendle;end
p( {:rest=>99})
p %{{{{#{"}}}"}}}}}

p :"jim";
p :'jim';
p %s/jim/;
p %s"jim";
p %s'jim';
p %s`jim`;
p %s[jim];
p %s{jim};
p %s(jim);
p %s<jim>;
p %s jim ;
x{ for bob in [100] do p(bob %(22)) end }

p [1,2,3,]
p({1=>2,3=>4,})
x{ p aaa,bbb,ccc=1,2,3  }
proc{|a,b,c,| p a,b,c }.call(1,2,3)

p (Module.instance_methods - Object.instance_methods).sort  
# an outer set of implicit parens is needed
p(Module.instance_methods - Object.instance_methods).sort  
#no outer implicit parens
"foo".slice (1-2).nil?   
#no outer implicit parens
p (1-2).nil?     
#outer implicit parens needed
p(1-2).nil?     
#no outer implicit parens needed
def self.z(*); end
def self.zz(*,&x); end
def self.zzz(&x); end

z z z z z z {}
z z z z z z do end

(/ 1/)
 p(/ 1/)
false and( true ? f : g )
false and( f .. g )
false and( f ... g )
 p 1&2 
#should be OperatorToken, not KeywordToken
 p 1|2 
#ditto
 p 1**2
 p 1*2
 p 1%(2)
 p 1^2
 p 1+2
 p 1-2
 p 1/2

 p 1?2:3  
#keyword

 p 1 ?2:3  
#keyword

 p 1? 2:3  
#keyword

 p 1?2 :3  
#keyword

 p 1?2: 3  
#keyword

 p 1 ? 2:3  
#keyword

 p 1 ?2 :3  
#keyword

 p 1 ?2: 3  
#keyword

 p 1? 2 :3  
#keyword

 p 1? 2: 3  
#keyword

 p 1?2 : 3  
#keyword

 p 1 ? 2 : 3  
#keyword
 p 1==2
 p 1===2
 p 1[2]  
#keyword
 p 1;2  
#keyword
 p 1,2  
#keyword
 p 1.2
 p 1.class  
#keyword
 p 1..2  
#keyword
 p 1...2  
#keyword
 p 1<2
 p 1>2
 p 1<=2
 p 1>=2
 p 1<<2

 p 1>>2
 p 1!=2  
#this is keyword
 p 1=~2
 p 1!~2  
#this is keyword
 p 1&&2  
#...
 p 1||2  
#...
 p 1<=>2

      define_method(:foo, &proc{:bar})
      define_method :foo, &proc{:bar}
      define_method(:foo) &proc{:bar}
      define_method :foo &proc{:bar}
      p :k, *nil
      p :k, *nil, &nil
      p  *nil
      p  *nil, &nil
p p :c, :d
def r;4 end; r=r.nil? 
p ?e.+?y
p ?e.+ ?y
p ?e.-?y
p ?e.*?y
p ?e./?y
p ?e.<<?y
p ?e.%?y
p ?e.**?y
p ?e.&?y

p 0.9
p 1.45000000000000000000000000000000000000001
p 9.999999999999999999999999999999999999999999
p 9.999999999999999999999999999999999999999999e999999999999999999999999999
p 0b0100011001
p 0o123456701
p 0123456701

p 0x123456789abcdefABCDEF01

p "Hi, my name is #{"Slim #{(4)>2?"Whitman":"Shady"} "}."
p "Hi, my name is #{"Slim #{(4)<2?"Whitman":"Shady"} "}."

p(String *Class)

def String.*(right) [self,right] end
def String.<<(right) [self,:<<,right] end
def String./(right) [self,:/,right] end
def String.[](right) [self,:[],right] end
def Class.-@; [:-@, self] end
p(String::Class)
p(String:: Class)
p(String ::Class)
p(String :: Class)
p(String/Class)
p(String/ Class)
p(String /Class/)
p(String / Class) 
#borken
p(String[Class])
p(String[ Class])
p(String [Class])
p(String [ Class])
p(String*Class)
p(String* Class)
p(String *Class)
p(String * Class)
undef :*,<<,/,[]

p(false::to_s)
p(false ::to_s)
p(false:: to_s)
p(false :: to_s)

  alias p? p
  alias P? p
  alias [] p
  alias <=> p

p:p8
false ? p: p8
p :p8
false ? p : p8

#false ? q:p8
false ? q: p8
#false ? q :p8
false ? q : p8

#false ? Q:p8  
#gives ruby indigestion
false ? Q: p8
#false ? Q :p8  
#gives ruby indigestion
false ? Q : p8

p?:p8
false ? p?: p8
p? :p8
false ? p? : p8

p??1
p? ?1
p(p?? 1 : 2)
p(p? ? 1 : 2)

P?:p8
false ? P?: p8
P? :p8
false ? P? : p8


P??1
P? ?1
p(P?? 1 : 2)
p(P? ? 1 : 2)

self.[]:p8
false ? self.[]: p8
self.[] :p8
false ? self.[] : p8

self.<=>:p8
false ? self.<=>: p8
self.<=> :p8
false ? self.<=> : p8

self <=>:p8
#false ? self <=>: p8  
#gives ruby indigestion
self <=> :p8
#false ? self <=> : p8  
#gives ruby indigestion

x{ mix=nil; p / 5/mix }

p :`

p{}
p {}

def nil.+(x) ~x end
def nil.[](*x) [x] end
p( p + 5 )
p( p +5 )
p( p+5 )
p( p[] )
p( p [] )
p( p [ ] )
class NilClass; undef +,[] end

#values
p Foou.new.[] -9     
p Foou.new.[] +9     
p Foou.new.[]!false  
p Foou.new.[] !false 
p Foou.new.[]~9      
p Foou.new.[] ~9     
p Foou.new.[] %(9)   
p Foou.new.[] /9/    
p Foou.new.[]$9      
p Foou.new.[]a0      
p Foou.new.[] $9     
p Foou.new.[] a0     

#ops
p Foou.new.[]-9      
p Foou.new.[]+9      
p Foou.new.[]<<9     
p Foou.new.[]%9      
p Foou.new.[]/9      

#lambdas (ops)
p Foou.new.[]{9}     
p Foou.new.[] {9} 

if p then p end

p({:foo=>:bar})   
#why does this work? i'd think that ':foo=' would be 1 token

p   EMPTY = 0
p   BLACK = 1
p   WHITE = - BLACK
p~4
p:f
p(~4){}
p(:f){}
p Array("foo\nbar")



p +(4)
p -(4)

p :'\\'

Foop.bar 1,2
Foop::bar 3,4


p %s{symbol}
p :$1
p :$98349576875974523789734582394578
p( %r{\/$})
p( %r~<!include:([\/\w\.\-]+)>~m)

p "#$a #@b #@@c #{$a+@b+@@c}"
p "\#$a \#@b \#@@c \#{$a+@b+@@c}"
p '#$a #@b #@@c #{$a+@b+@@c}'
p '\#$a \#@b \#@@c \#{$a+@b+@@c}'
p %w"#$a #@b #@@c #{$a+@b+@@c}"
p %w"\#$a \#@b \#@@c \#{$a+@b+@@c}"
p %W"#$a #@b #@@c #{$a+@b+@@c}"
p %W"\#$a \#@b \#@@c \#{$a+@b+@@c}"
p %Q[#$a #@b #@@c #{$a+@b+@@c}]
p %Q[\#$a \#@b \#@@c \#{$a+@b+@@c}]
p `echo #$a #@b #@@c #{$a+@b+@@c}`
p `echo \#$a \#@b \#@@c \#{$a+@b+@@c}`
p(/#$a #@b #@@c #{$a+@b+@@c}/)
#p(/\#$a \#@b \#@@c \#{$a+@b+@@c}/) #moved to w.rb

x{ compile_body=outvar='foob'}
p "#{}"
p "#(1)"
def intialize(resolvers=[Hosts.new, DNS.new]) end
def environment(env = File.basename($0, '.*')) end

def ==(o) 444 end
def String.ffff4() self.to_s+"ffff" end
p *[]
#abc123def


p(1.+1)
p pppp
p "\""
p(/^\s*(([+-\/*&\|^]|<<|>>|\|\||\&\&)=|\&\&|\|\|)/)
p(:%)

x{ p( { :class => class_=0}) }
x{ p cls_name = {}[:class] }

p foo
p "#{$!.class}"
p :p
p(:p)
p(:"[]")
p :"[]"
p("\\")
p(/\\/)
p(/[\\]/)
p 0x80
p ?p
p 0.1
p 0.8
p 0.9
p(-1)
p %/p/
p %Q[<LI>]
i=99
p %Q[<LI><A HREF="#{i[3]}.html\##{i[4]}">#{i[0]+i[1]+(i[2])}</A>\n]
p(:side=>:top)
p %w[\\]
p %w[\]]
p :+
p 99 / 3
x{ a=99;b=3;p 1+(a / b) }
p %Q[\"]
p %Q[ some [nested] text]

p '\n'
p "\n"
p %w/\n/

p %W/\n/
p(/\n/)
  p `\n`
p(%r[foo]i)
p ENV["AmritaCacheDir"]
x{ p f = 3.7517675036461267e+17 }
p $10
p $1001

def jd_to_wday(jd) (jd + 1) % 7 end
p jd_to_wday(98)
x{ p    pre = $` }
p $-j=55

def empty() end
def printem2 a,b,c; p(a +77); p(b +77); p(c +77) end
def three() (1+2) end

def d;end
def d()end
def d(dd)end

p proc{||}
p "\v"
x{ c=0;  while c == /[ \t\f\r\13]/; end }





def ~@; :foo end
undef ~@
alias ~@ non
alias non ~@
p :~@
a.~@
a::~@

JAVASCRIPTS.each { |script| @xml.script :type => 'text/javascript', :src => "/javascripts/#{script}.js" do end }
x{ script=0; @xml.script :type => text/javascript, :src => "/javascripts/#{script}.js" do end }
sources.each { |src| ant.src :path => src }

x{sn = m.sn :sen}
x{sn = m.sn %(sen)}
x{sn = m.sn ?s}
x{sn = m.sn /s/}
x{sn = m::sn :sen}

a b do end
a b.c do end
a b() do end
a b.c() do end
x{b=1;a b do end}    
#b should be local var, both times
x{b=1;a=b do end} 
#do applies to b
x{a=b do end}     
#do applies to b
x{a b=c do end}
x{c=1;a b=c do end}
6._?
6._=7
6._ =7
6._= 7
6._ = 7
E if defined? :E

defined? %/f/
defined? []
defined?({})
defined? ::A
next ::A
break ::A
return ::A
defined? ?A
defined? -1
defined? -1.0
defined? +1
defined? +1.0

defined? ~1
next ~1
return ~1
break ~1


def a.b; end rescue b0

def maybe(chance = 0.5)end
return rval / precision
0e0

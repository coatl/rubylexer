module Ruby1_9OneLiners
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
    '$f.($x,$y)',
    '$f::($x,$y)',
    '__ENCODING__',
    '__ENCODING__ +"foo"',
    'module __ENCODING__::A; end',
  ]

  EXPECT_1_METHOD=[
    'def self.foo; 1 end',
    '->{ foo=1 }; foo',
    '->do foo=1 end; foo',
    'def __FILE__.foo; 1 end',
    'def __LINE__.foo; 1 end',
    'def a(b,*c,d) 1 end',
    'def a(*c,d) 1 end',
    'def Z::a(b,*c,d) 1 end',
    'def Z::a(*c,d) 1 end',
    'a{|b,*c,d| 1 }',
    'a{|*c,d| 1 }',
    'def a(b,(x,y),d) 1 end',
    'def a((x,y),d) 1 end',
    'def Z::a(b,(x,y),d) 1 end',
    'def Z::a((x,y),d) 1 end',
    'a{|b,(x,y),d| 1 }',
    'a{|(x,y),d| 1 }',
    'def a(b,(x,*y),d) 1 end',
    'def a((x,*y),d) 1 end',
    'def Z::a(b,(x,*y),d) 1 end',
    'def Z::a((x,*y),d) 1 end',
    'a{|b,(x,*y),d| 1 }',
    'a{|(x,*y),d| 1 }',
    'def a(b,(x,(y,z)),d) 1 end',
    'def a((x,(y,z)),d) 1 end',
    'def Z::a(b,(x,(y,z)),d) 1 end',
    'def Z::a((x,(y,z)),d) 1 end',
    'a{|b,(x,(y,z)),d| 1 }',
    'a{|(x,(y,z)),d| 1 }',
    'module __ENCODING__::A include B; end',
    'def __ENCODING__; 342 end',
    'def __ENCODING__.foo; 1 end',
    'def Z::__ENCODING__; 342 end',
    #'def Z::__ENCODING__.foo; 1 end', #oops, 2 methods here
  ]
end

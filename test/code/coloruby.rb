require 'rubygems'
require 'rubylexer'
require 'term/ansicolor'


def coloruby file,fd=open(file)
  lexer=RubyLexer.new(file,fd)
  while true
    token=lexer.get1token
    break if RubyLexer::EoiToken===token
    print token.colorize
  end
ensure
  print Term::ANSIColor.reset
end

class RubyLexer
  class Token
    include Term::ANSIColor

    def colorize
      color+ident.to_s
    end
  end

  class VarNameToken
    alias color blue
  end

  class MethNameToken
    alias color green
  end

  class OperatorToken
    alias color cyan
  end

  class KeywordToken
    def colorize
      if /[^a-z]/i===ident
        yellow+ident
      else
        red+ident
      end
    end
  end

  class WsToken
    def colorize
      black+ident
    end
  end

  class NewlineToken
    alias color black
  end

  class ZwToken
    def colorize; '' end
  end

  class FileAndLineToken
    def colorize; '' end
  end

  class ImplicitParamListStartToken
    def colorize; '' end    
  end

  class ImplicitParamListEndToken
    def colorize; '' end    
  end

  class IgnoreToken
    def colorize
      dark+green+ident+reset
    end
  end
 
  class EscNlToken
    def colorize
      yellow+ident
    end
  end

  class NumberToken
    def color; dark+blue end
  end

  class SymbolToken
    def colorize
      if StringToken===ident
        dark+blue+':'+ident.colorize
      else
        dark+blue+ident
      end
    end
  end

  class StringToken
    def colorize
      magenta+open+
        elems.map{|elem|
          if String===elem
            magenta+elem
          else
            yellow+'#'+elem.colorize
          end
        }.join+
      magenta+close
    end
  end

  class RubyCode
    def colorize
      ident.map{|tok| tok.colorize }.join
    end
  end

  class HerePlaceholderToken
    def colorize
      "#{blue}<<#{'-' if @dash}#{ender}"
    end
  end

  class HereBodyToken
    def colorize
      headtok.string.colorize
    end
  end
end

if __FILE__==$0
  if ARGV.first=='-e'
    coloruby ARGV[1],ARGV[1]
  else
    coloruby ARGV.first
  end
end


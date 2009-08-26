require 'rubygems'
require 'rubylexer'
require 'term/ansicolor'


def coloruby file,fd=open(file)
  lexer=RubyLexer.new(file,fd)
  begin
    token=lexer.get1token
    print token.colorize
  end until RubyLexer::EoiToken===token
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
    def colorize
      dark+blue+ident+reset
    end
  end

  class SymbolToken
    def colorize
      if StringToken===ident
        dark+blue+':'+ident.colorize+reset
      else
        dark+blue+ident+reset
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

  class EoiToken
    def colorize
      return '' #gyaah, @offset has off by one errors
      data=begin
             @file.pos=@offset-1
             @file.read
           rescue
             @file[@offset-1..-1]
           end
      dark+green+data+reset
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


require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'algorithm/diff'
require 'pathname'

#require "test/code/all_the_gems"
require "test/code/tarball"

def fetch_with_cache(base,path,cachedir)

path[-1]==?/ and path+='index.html'

#make sure right dir structure for this path exists in cachedir
dnames=Pathname.new(path)
dirs=[]
while dnames.to_s["/"]
  dnames=dnames.dirname
  dirs.unshift cachedir+dnames.to_s
end
dirs.each{|dir| Dir.mkdir dir rescue nil}

#find latest cached version of this file in cachedir
latest_fname=nil
latest_date=Time.mktime '1970'
Dir[cachedir+path+".*"].each{|fname| 
  mtime=File.mtime(fname)
  if mtime>=latest_date
    latest_date=mtime
    latest_fname=fname
  end
}

options={"User-Agent"=>"all_the_raas.rb"}

#extract etag from latest name
if latest_fname
  latest_etag=latest_fname[%r{\A#{Regexp.quote cachedir+path}\.(.*)\Z},1]
  options['If-None-Match']=latest_etag unless latest_etag==''
end

#refetch the file if it has changed, otherwise use cached copy
begin
  open(base+path, options){|net|
    latest_fname=cachedir+path+"."+(net.meta['etag']||'')
    File.open(latest_fname,'w'){|f| f.write net.read }
  }
  #puts "fetched a fresh #{base+path}"
rescue OpenURI::HTTPError=>e
  raise e unless e.io.status.first=='304' and /Not Modified/i===e.io.status.last
  #puts "reusing latest #{latest_fname}"
end

return File.open latest_fname
end

def changeratio(s1,s2)
  diffslen=s1.diff(s2).inject(0){|sum,(msg,pos,data)| 
    sum+data.size 
  }
  return diffslen.to_f/(s1.size+s2.size)
end

def sameproject?(s1,s2)
   s1.casecmp(s2).zero? or 
   s1.index(s2)==0 or 
   s2.index(s1)==0 or
   changeratio(s1,s2)<0.5
end


if __FILE__==$0
base="http://raa.ruby-lang.org/"

offset=(ENV['OFFSET']||0).to_i
limit=(ENV['LIMIT']||20).to_i

cachedir="jewels/"

Dir.mkdir cachedir rescue nil

#fetch list of all projects from raa's all.html
all_raas=fetch_with_cache(base,"all.html",cachedir)
tree=Hpricot(all_raas)
tree/=:table
tree.search(:thead).remove
tree/=:tr
#tree=tree[offset,limit]
urls=tree.map{|row|
  begin
    row.search(:td).first.search(:a).first[:href] 
  rescue Exception=>e
    puts "failure #{e} in row #{row}" #wank about it
    nil
  end
}

RUBYFORGE=%r{\Ahttp://(?:[a-z0-9_+-:]+\.)*rubyforge.org/}i

PROTOCOLS=%w[http https ftp]
EXTENSIONS=%w[tar zip rb tgz tbz2 tbz gem]
EXTRA_EXTENSIONS=%w[gz bz2 Z]
EXTRA_EXTENSIONS_REX="\\.(?:#{EXTRA_EXTENSIONS.join'|'})"
VERSIONTOO='' #was: "(?:[_-](.*))"
ENDINGS="\\.(?:#{EXTENSIONS.join('|')})(?:#{EXTRA_EXTENSIONS_REX})?"
TARBALL=%r<
  \A(?:#{PROTOCOLS.join('|')})://
  (?:[^/]+/)+
  (.*)
  #{VERSIONTOO}
  #{ENDINGS}
  \Z
>ixo

$rubyforge_urls=0 

#pp urls
#crawl raa's individual page for each project, looking for dl link
urls.map!{|url|
  begin
     tree=Hpricot(fetch_with_cache(base,url,cachedir))
#    if url
#      url=base+url
#      tree=Hpricot(open(url))
#    end
    project=tree.search(:title).inner_html[/\ARAA - (.*)\Z/,1]
    tree/=:table
    trs=tree/:tr
    dl=trs.find{|tr| 
      !tr.search("th[text()^='Download']").empty?
    }
    newurl=dl.search('td/a').first
    if newurl
      url=newurl[:href]
      %r{\A(#{PROTOCOLS.join('|')})://}io===url or url="http://"+url
      if RUBYFORGE===url
        unless TARBALL===url and not /\.gem\Z/===url
          url=nil
          $rubyforge_urls += 1
        end
      end
      url.slice!(/\#.*\Z/) if url #trim off url section
      [url,project] 
    else
      puts "couldn't find td/a in #{base+url}"
      [nil,nil]
    end
  rescue Interrupt=>e 
    raise if e.class==Interrupt #^c only, dammit! #$^$&%'n Timeout::Error
  rescue Exception=>e
    puts "error: #{e} during url #{url}"
    #wank about it
    [nil,nil]
  end 
}


#pp urls
#resolve list of dl urls into urls to 'tarballs' (which is meant to include zip, gem, etc)
#dl urls found on raa might be a direct link to a tarball, or point to a page that
#points to the tarball
urls.map!{|url,project|
  if TARBALL===url
    urlproject=$1
    versionstart=urlproject.rindex(/[_-]/)
    urlproject.slice! versionstart..-1 if versionstart
    if sameproject?(urlproject,project)
      url
    else
      puts "uh-oh, project #{project} not found in url #{url}. urlproject was #{urlproject}"
    end
      
  elsif url
    href=nil
    begin
      tree=Hpricot(open(url))
      tree/=:a
      tarball_url=tree.find{|a| 
         href=a[:href] or next
         unless %r[\A(?:#{PROTOCOLS.join('|')})://]o===href #relative url?
#           url+="/" unless url[-1]==?/
           href="/"+href unless href[0]==?/
           href=url[%r{\A[^/]+//[^/]+}]+href
         end
         TARBALL===href 
      }
      if tarball_url
          urlproject=$1
          versionstart=urlproject.rindex(/[_-]/)
          urlproject.slice! versionstart..-1 if versionstart
          if sameproject?(urlproject,project)
            href
          else
            puts "uh-oh, project #{project} not found in url #{url}. urlproject was #{urlproject}"
          end
      end

    rescue Interrupt=>e
      raise if e.class==Interrupt
      puts "error: #{e} during page scan of url #{url}"
    rescue Exception=>e
      puts "error: #{e} during page scan of url #{url}"
      nil
    end
  end
}

/unzip ([^\s]+)[\s\n]/i===`unzip -v`
unzip="unzip"
unzip+=" -L" if $1[0..2].to_f>=5.5

pp urls
#for each tarball url actually found, dl the tarball
urls.compact.each{|url| 
  begin
    Tarball.dl_and_unpack(cachedir,url) 
  rescue Interrupt=>e
    raise if e.class==Interrupt
    #else do nothing
  rescue Exception
    #do nothing
  end
}

p [:$rubyforge_urls, $rubyforge_urls]
end

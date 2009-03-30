require 'open-uri'

class Tarball
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

def Tarball.unpack1gem(gem)
  dir=gem.dup
  dir[/\.gem$/]=''
  Dir.mkdir dir rescue nil
  
  system "tar x -f #{gem} -C #{dir}"
  files_in_dir=Dir[dir+"/*"]-[dir+"/data.tar.gz",dir+"/metadata.gz"]
  files_in_dir.empty? or puts "gem archive toplevel contains extra files: #{files_in_dir.join(' ')}"
  system "gunzip -f #{dir}/metadata.gz -c > #{dir}/metadata"
  system "tar xz -f #{dir}/data.tar.gz -C #{dir}"


  (File.unlink gem rescue nil) if File.exist? dir+"/metadata.gz" and File.exist? dir+"/data.tar.gz"
  (File.unlink dir+"/metadata.gz" rescue nil) if File.exist? dir+"/metadata"
  files_in_dir=Dir[dir+"/*"]-[dir+"/data.tar.gz",dir+"/metadata.gz",dir+"/metadata"]-files_in_dir
  (File.unlink dir+"/data.tar.gz" rescue nil) unless files_in_dir.empty?
end

def Tarball.dl_and_unpack(cachedir,url)
  projectname=url[%r{[^/]+\Z}]
  localname=cachedir+projectname
  projectname.sub!(/#{ENDINGS}\Z/o,'')+"/"
  localdir= cachedir+projectname
  #localdir=localname.sub(/#{ENDINGS}\Z/o,'')+"/"

  if File.exist? localdir 
   puts "skipping already extant #{localdir}"
   return
  end
  begin
  open(localname,"w"){|disk|
    open(url){|net|
      while buf=net.read(40960)
        disk.write buf
      end
    }
  }
  rescue Interrupt=>e
    File.unlink localname rescue nil
    raise if e.class==Interrupt
    return
  rescue Exception
    File.unlink localname rescue nil
    return
  end

  unpack(cachedir,localname,projectname,localdir)
end

def Tarball.unpack(cachedir,localname,
                   projectname=localname[/\/(.*)#{ENDINGS}\Z/,1],
                   localdir=localname.sub(/#{ENDINGS}\Z/o,'')+"/")
  cachedir[-1]==?/ or fail
  localname[0,cachedir.size]==cachedir or fail

  if File.exist? localdir 
   puts "skipping already extant #{localdir}"
   return
  end

  #rename .tgz,.tbz2? to the full form
  case localname
  when /\.tgz\Z/: 
    oldln=localname
    localname=localname[0...-4]+".tar.gz"
  when /\.tbz2?\Z/:
    oldln=localname
    localname=localname[0...-$&.size]+".tar.bz2"
  end
  File.rename oldln, localname if oldln

  #remove any gz or bz2 whole-archive compression
  case localname
  when /\.bz2\Z/: 
    system "bunzip2 "+localname or return
    localname=localname[0...-$&.size]
  when /\.(gz|Z)\Z/: 
    system "gunzip -f "+localname or return
    localname=localname[0...-$&.size]
  end

  #now actually unpack the archive
  case localname
  when /\.rb\Z/: 
    Dir.mkdir localdir
    File.rename localname, localdir+localname[%r{[^/]+\Z}]
  when /\.gem\Z/: unpack1gem localname
  when /\.zip\Z/:
   filelist=`unzip -L -l #{localname}`
   if $?>>8 > 1 
     puts "invalid zip file #{localname}"
     return
   end
   filelist=filelist.split("\n")[3...-2]
   wellformed=!filelist.find{|entry|
     entry[/\A\s*[^\s]+\s+[^\s]+\s+[^\s]+\s+\^?(.*)\Z/,1][0...projectname.size] != projectname
   } 
   if wellformed 
     zipopts=" -d #{cachedir}"
   else
     zipopts=" -d #{localdir}"
     Dir.mkdir localdir
   end
   puts "unzip -L #{localname} #{zipopts}"
   system "unzip -L #{localname} #{zipopts}"
   (File.unlink localname rescue nil) if $?>>8 <= 1

  when /\.tar\Z/:
   wellformed=!`tar tf #{localname}`.split("\n").find{|entry|
     entry[0...projectname.size] != projectname
   }
   if wellformed
     taropts=" -C #{cachedir}"
   else
     taropts=" -C #{localdir}"
     Dir.mkdir localdir
   end
   system "tar xf #{localname} #{taropts}"
   File.unlink localname rescue nil

  else fail "unknown tarball type: #{localname}"
  end
end

end


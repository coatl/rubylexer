#http://gems.rubyforge.org/yaml
#http://gems.rubyforge.org/gems/#{name}-#{version}.gem

require 'rubygems'
require 'yaml'
require 'open-uri'

require "test/code/tarball"

limit=(ENV['LIMIT']||20).to_i
offset=(ENV['OFFSET']||0).to_i

specs=open(ARGV.first||"http://gems.rubyforge.org/yaml"){|net| YAML.load net }

name2vers={}
specs.each{|bogus,spec| 
  name2vers[spec.name]||=[]
  name2vers[spec.name]<<spec.version
}
specs=nil

name2vers.each_key{|name|
  name2vers[name]=name2vers[name].max
}
#name2vers=name2vers.to_a[limit,offset]

name2vers.each{|name,version|
  begin
    Tarball.dl_and_unpack("jewels/","http://gems.rubyforge.org/gems/#{name}-#{version}.gem")
  rescue Interrupt: exit
  rescue Exception: #do nothing
  end
}

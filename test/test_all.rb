$:<<File.expand_path(File.dirname(File.dirname(__FILE__)))
require 'test/code/regression'
require 'test/code/test_1.9'

Dir['test/test_*.rb'].each{|test| require test }

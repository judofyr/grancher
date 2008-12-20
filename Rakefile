require 'echoe'
require 'hanna/rdoctask'
require 'lib/grancher/task'

Echoe.new('grancher') do |p|
  p.project = "dojo"
  p.author = "Magnus Holm"
  p.email = "judofyr@gmail.com"
  p.summary = "Easily copy folders and files to other Git branches"
  p.runtime_dependencies = ["gash"]
  p.rdoc_options += ["--main", "Grancher", "--title", "Grancher"]
end

Grancher::Task.new do |g|
  g.branch = 'gh-pages'
  g.push_to = 'origin'
  
  g.directory 'doc'
end
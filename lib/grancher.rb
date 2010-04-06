require 'gash'

# == What is Grancher?
#
# With Grancher you can easily copy folders and files to a Git branch.
#
# === How?
# ==== As a library
#
#   require 'grancher'
#   grancher = Grancher.new do |g|
#     g.branch = 'gh-pages'         # alternatively, g.refspec = 'ghpages:/refs/heads/ghpages'
#     g.push_to = 'origin'
#     g.repo = 'some_repo'          # defaults to '.'
#     g.message = 'Updated website' # defaults to 'Updated files.'
#   
#     # Put the website-directory in the root
#     g.directory 'website'
#     
#     # doc -> doc
#     g.directory 'doc', 'doc'
#     
#     # README -> README
#     g.file 'README'
#     
#     # AUTHORS -> authors.txt
#     g.file 'AUTHORS', 'authors.txt'
#     
#     # CHANGELOG -> doc/CHANGELOG
#     g.file 'CHANGELOG', 'doc/'
#   end
#
#   grancher.commit
#   grancher.push
#
# ==== As a Raketask
#
# Instead of:
#
#   require 'grancher'
#   Grancher.new do |g|
#     ...
#   end
#
# Do:
#
#   require 'grancher/task'
#   Grancher::Task.new do |g|
#     ...
#   end
#
# See Grancher::Task for more information.
#
# === Keeping the files already in the branch
#
# By default, Grancher will remove any files already in the branch. Use
# keep and keep_all to change this behaviour:
#
#    Grancher.new do |g|
#      # Only keep some files/folders:
#      g.keep 'index.html', 'test', 'lib/grancer'
#      
#      # Keep all the files in the repo:
#      g.keep_all
#    end
# 
#
class Grancher
  attr_accessor :branch, :refspec, :push_to, :repo, :message
  attr_reader :gash, :files, :directories
  
  def initialize(&blk)
    @directories = {}
    @files = {}
    @keep = []
    @repo = '.'
    @message = 'Updated files.'
    if block_given?
      if blk.arity == 1
        blk.call(self)
      else
        self.instance_eval(&blk)
      end
    end
  end
  
  # Returns our Gash-object
  def gash
    @gash ||= Gash.new(@repo, @branch)
  end
  
  # Stores the directory +from+ at +to+.
  def directory(from, to = nil)
    @directories[from.chomp('/')] = to
  end
      
  # Stores the file +from+ at +to+.
  def file(from, to = nil)
    @files[from] = to
  end
  
  # Keeps the files (or directories) given.
  def keep(*files)
    @keep.concat(files.flatten)
  end
  
  # Keep all the files in the branch.
  def keep_all
    @keep_all = true
  end

  # Full git refspec to push to. Setting g.refspec will replace g.branch. Used when the remote
  # branch is different to the local branch. Any git refspec is valid ('man git-push' for details)
  def refspec=(refspec)
    if refspec =~ /^\+?(.*)(?:\:.*)$/
      @branch = $1
    else
      raise ArgumentError, "refspec syntax error. Should be: branch:refs/heads/branch"
    end
    @refspec = refspec
  end

  def branch=(branch)
    @refspec = "#{branch}:refs/heads/#{branch}"
    @branch = branch
  end

  # Pushes the branch to the remote.
  def push
    gash.send(:git, 'push', @push_to, @refspec)
  end
  
  # Commits the changes.
  def commit(message = nil)
    build.commit(message || message())
  end
  
  private

  def build
    clear_all_but_kept unless @keep_all
    add_directories
    add_files
    gash
  end
  
  def clear_all_but_kept
    kept = {}
    @keep.each do |thing|
      kept[thing] = gash[thing]
    end

    gash.clear

    kept.each do |path, thing|
      gash[path] = thing
    end
  end
  
  def add_directories
    @directories.each do |from, to|
      Dir[from + '/**/*'].each do |file|
        next if File.directory?(file)
        content = File.read(file)
        base = if to
          file[0...from.length] = to
          file
        else
          file[from.length + 1..-1]
        end
        gash[base] = content
      end
    end
  end
  
  def add_files
    @files.each do |from, to|
      content = File.read(from)
      base = if to
        if to[-1] == ?/
          to + from
        else
          to
        end
      else
        from
      end
      gash[base] = content
    end
  end
end
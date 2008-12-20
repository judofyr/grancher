require File.join(File.dirname(__FILE__), '..', 'grancher')

class Grancher
  class Task
    # Defines a task named +name+ where the block given behaves like a
    # Grancher-object.
    #
    # If +push_to+ is set, it will automatically push the branch when done.
    def initialize(name = 'publish', &blk)
      @grancher = Grancher.new(&blk)
      define_task(name)
    end
    
    private
    
    def define_task(name)
      desc(if @grancher.push_to
        "Builds and pushes the #{@grancher.branch}-branch"
      else
        "Builds the #{@grancher.branch}-branch"
      end)
      task(name) do
        @grancher.commit
        @grancher.push if @grancher.push_to
      end
    end
  end
end
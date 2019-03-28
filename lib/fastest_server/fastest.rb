module FastestServer
  class Fastest
    def initialize(targets, max, verbose)
      @max = [max, targets.size].min
      @jobs = targets
      @verbose = verbose
      @checkbook = {}
      @workers = Array.new(@max) { |i| Worker.new(i, @jobs, @checkbook) }
      @watcher = Thread.new { watch } if @verbose
    end

    def give_me_answer
      join
      clear_screen if @verbose
      Formatter.new(@checkbook.values).display!(@verbose)
    end

    private

    def watch
      refresh until @jobs.empty? && @workers.all?(&:done?)
      2.times { refresh }
    end

    def refresh
      clear_screen
      puts "Status: "
      @workers.each { |w| puts "#{w.name}: #{w.current_status!}" }
      sleep(1)
    end

    def clear_screen
      system("clear || cls")
    end

    def join
      @workers.each(&:join)
      @watcher.join if @verbose
    end
  end
end
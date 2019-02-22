module FastestServer
  class Worker

    attr_reader :name

    def initialize(name, queue, checkbook)
      @done = false
      @name = "Worker %02d" % name
      @queue = queue
      @checkbook = checkbook
      @pid = Thread.new { perform }
    end

    def current_status!
      return @target if @target == "Done"
      ret = @target_string[0..MAX_WIDTH]
      @target_string = "#{@target_string[1..-1]}#{@target_string[0]}"
      return ret
    end

    def join
      @pid.join
    end

    def done?
      @done
    end

    private

    def perform
      while target = @queue.shift
        @done = false
        set_status(target)
        @checkbook[target] = Ping.perform(target)
        set_status("Done")
        @done = true
        sleep(1)
      end
    end

    MAX_WIDTH = 40
    FIX_WHITESPACE = 5

    def set_status(target)
      @target = target
      if target.length > (MAX_WIDTH - FIX_WHITESPACE)
        @target_string = target + " " * FIX_WHITESPACE
      else
        @target_string = target.ljust(MAX_WIDTH)
      end
    end
  end
end
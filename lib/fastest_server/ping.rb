module FastestServer
  class Ping
    class << self
      def get_count
        @count ||= 4
      end

      def set_count(count)
        @count = [[count, 1].max, 100].min
      end

      def perform(server)
        get_pinger.new(server).perform
      end

      private

      def get_pinger
        if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM)
          WindowsPing
        else
          LinuxPing
        end
      end
    end

    def initialize(server)
      @server = server
    end

    def execute_ping_command
      raise NotImplementedError, "Subclass must implement execute_ping_command method."
    end

    # ping and parse the result
    def perform
      result, status = execute_ping_command

      # we only process `successful` ping.
      return parsed(status: status) unless status == 0

      _, site, ip, _ = result.match(regex_ping)[0].split(" ")
      ip.gsub!(regex_filter, "")
      loss = result.match(regex_loss) ? $&.to_f : 100

      if stat = result.match(regex_stat)
        parsed(ip: ip, site: site, loss: loss,
              max: stat["max"].to_f, min: stat["min"].to_f,
              avg: stat["avg"].to_f, stddev: stat["stddev"]&.to_f || 0.0)
      else
        parsed(ip: ip, site: site, loss: loss, status: status)
      end
    end

    def method_missing(name, *args)
      if name =~ /regex_/
        self.class.const_get(name.upcase)
      else
        super
      end
    end

    # From MacOX `ping` manual
    #  
    # EXIT STATUS
    #      The `ping` utility exits with one of the following values:
    #      0         At least one response was heard from the specified host
    #
    #      2         The transmission was successful but no responses were received.  
    # 
    #      any other value
    #                An error occurred.  These values are defined in <sysexists.h>
    #
    def parsed(**arguments)
      {ip: @server, server: @server, site: @server, status: 0,
       loss: 100, max: 0.0, min: 0.0, avg: 0.0, stddev: 0.0}.merge(arguments)
    end
  end

  class WindowsPing < Ping
    REGEX_PING = /Pinging.*/
    REGEX_FILTER = /\[|\]/
    REGEX_LOSS = /\(\d*% loss\)/
    REGEX_STAT = /Minimum = (?<min>\d+)ms, Maximum = (?<max>\d+)ms, Average = (?<avg>\d+)ms(?<stddev>)/

    def execute_ping_command
      result = `chcp 437 && ping -n #{Ping.get_count} #@server`
      status = $?
      [result, $?]
    end
  end

  class LinuxPing < Ping

    REGEX_PING = /PING.*/
    REGEX_FILTER = /\(|\)|:/
    REGEX_LOSS = /(?<loss>\d*)% packet loss/
    REGEX_STAT = /(?<min>\d*.\d*)\/(?<avg>\d*.\d*)\/(?<max>\d*.\d*)\/(?<stddev>\d*.\d*) ms/

    def execute_ping_command
      result = `ping -c #{Ping.get_count} -q #@server`
      status = $?
      [result, $?]
    end
  end
end

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

    def perform
      raise NotImplementedError, "Subclass must implement perform method."
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
    REGEX_STAT = /Minimum = (?<min>\d+)ms, Maximum = (?<max>\d+)ms, Average = (?<avg>\d+)ms/

    def perform
      result = `chcp 437 && ping -n #{Ping.get_count} #@server`
      status = $?

      return parsed(status: status) unless result.match(REGEX_PING)

      _, site, ip, _ = $&.split(" ")
      ip.gsub!(REGEX_FILTER, "")
      return parsed(status: status, ip: ip, site: site) unless status == 0

      stat = result.match(REGEX_STAT)
      parsed(ip: ip,
             site: site,
             loss: result.match(REGEX_LOSS)[0].to_f,
             max: stat["max"].to_i,
             min: stat["min"].to_i,
             avg: stat["avg"].to_i,
             stddev: 0)
    end
  end

  class LinuxPing < Ping

    REGEX_PING = /PING.*/
    REGEX_FILTER = /\(|\)|:/
    REGEX_LOSS = /(?<loss>\d*)% packet loss/
    REGEX_STAT = /(?<min>\d*.\d*)\/(?<avg>\d*.\d*)\/(?<max>\d*.\d*)\/(?<stddev>\d*.\d*) ms/

    # ping and parse the result
    def perform
      result = `ping -c #{Ping.get_count} -q #@server`
      status = $?

      # we only process `successful` ping.
      return parsed(status: status) unless status == 0

      _, site, ip, _ = result.match(REGEX_PING)[0].split(" ")
      ip.gsub!(REGEX_FILTER, "")

      loss = result.match(REGEX_LOSS) ? $&.to_f : 100

      if stat = result.match(REGEX_STAT)
        parsed(ip: ip, site: site, loss: loss,
               max: stat["max"].to_f, min: stat["min"].to_f,
               avg: stat["avg"].to_f, stddev: stat["stddev"].to_f)
      else
        parsed(ip: ip, site: site, loss: loss, status: status)
      end
    end

  end
end

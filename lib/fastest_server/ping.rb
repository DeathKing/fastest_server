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
        elsif (/darwin/ =~ RUBY_PLATFORM)
          DarwinPing
        elsif
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

    def parsed(**arguments)
      {ip: @server, server: @server, site: @server, status: 0,
       max: 0.0, min: 0.0, avg: 0.0, stddev: 0.0}.merge(arguments)
    end
  end

  class WindowsPing < Ping
  end

  class DarwinPing < Ping

    REGEX_PING = /PING.*/
    REGEX_FILTER = /\(|\)|:/
    REGEX_LOSS = /(?<loss>\d*\.\d*)% packet loss/
    REGEX_STAT = /(?<min>\d*.\d*)\/(?<avg>\d*.\d*)\/(?<max>\d*.\d*)\/(?<stddev>\d*.\d*) ms/

    # ping and parse the result
    def perform
      #FIXME: may not thread safe
      result = `ping -c #{Ping.get_count} -q #@server`
      status = $?

      # if we cannot find a valid information line, just return nil
      return parsed(status: status) unless result.match(REGEX_PING)
      _, site, ip, _ = $&.split(" ")
      ip.gsub!(REGEX_FILTER, "")

      return parsed(status: status, ip: ip, site: site) unless status == 0

      stat = result.match(REGEX_STAT)
      parsed(ip: ip,
             site: site,
             loss: result.match(REGEX_LOSS)[0].to_f,
             max: stat["max"].to_f,
             min: stat["min"].to_f,
             avg: stat["avg"].to_f,
             stddev: stat["stddev"].to_f)
    end

  end
end

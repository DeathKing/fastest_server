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
        @pinger ||= if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM)
                      WindowsPing
                    elsif (/darwin/ =~ RUBY_PLATFORM)
                      UnixPing
                    elsif
                      LinuxPing
                    end
      end
    end

    def initialize(server)
      @server = server
    end

    def perform
      raise NotImplementedError
    end

  end

  class WindowsPing < Ping
  end

  class UnixPing < Ping

    REGEX_PING = /PING.*/
    REGEX_FILTER = /\(|\)|:/
    REGEX_LOSS = /(\d*.\d*)% packet loss/
    REGEX_STAT = /(?<min>\d*.\d*)\/(?<avg>\d*.\d*)\/(?<max>\d*.\d*)\/(?<stddev>\d*.\d*) ms/

    # ping and parse the result
    def perform
      #FIXME: may not thread safe
      result = `ping -c #{Ping.get_count} -q #@server`
      status = $?

      # if we cannot find a valid information line, just return nil
      return useless_server unless result.match(REGEX_PING)
      _, site, ip, _ = $&.split(" ")
      ip.gsub!(REGEX_FILTER, "")

      base = useless_server(status)

      return base.merge(ip: ip) unless status == 0

      stat = result.match(REGEX_STAT)
      return base.merge({
          ip: ip,
          site: site,
          loss: result.match(REGEX_LOSS)[0].to_f,
          max: stat["max"].to_f,
          min: stat["min"].to_f,
          avg: stat["avg"].to_f,
          stddev: stat["stddev"].to_f})
    end

    private

    def useless_server(status=-1)
      {site: @server, ip: @server, target: @server, status: status,
       loss: 100, max: 0, min: 0, avg: 0, stddev: 0 }
    end
  end
end

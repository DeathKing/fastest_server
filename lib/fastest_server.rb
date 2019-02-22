require "fastest_server/version"
require 'fastest_server/ping'
require 'fastest_server/worker'
require 'fastest_server/formatter'
require 'fastest_server/fastest'
require 'clamp'

module FastestServer
  class FastestCommand < Clamp::Command
    option ["-f", "--file"], "FILENAME", "load a list of servers from FILENAME" do |f|
      if File.exist?(f)
        @servers ||= []
        @servers += IO.read(f).split("\n").map(&:strip).reject(&:empty?)
      end
    end
    option ["-c", "--count"], "N", "stop after sending (and receiving) N ECHO_RESPONSE packets",
           default: 10 do |s|
      Ping.set_count(Integer(s))
    end
    option ["-v", "--verbose"], :flag, "show more useful information", default: false
    option ["-j", "--job"], "N", "maximum parallel ping jobs", default: 4 do |s|
      [[1, Integer(s)].max, 12].min
    end
    option "--version", :flag, "show version" do
      puts MyGem::VERSION
      exit_success
    end

    parameter "[SERVERS] ...", "the servers domain or ip that want to test with",
              attribute_name: :server_lists do |s|
      @servers ||= []
      @servers << s if s
    end

    def exit_success
      exit(0)
    end

    def execute
      if @servers.nil? || @servers.empty?
        puts(help)
        exit_success
      end

      Fastest.new(@servers, job, verbose?).give_me_answer
    end
  end
end

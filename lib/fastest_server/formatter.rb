module FastestServer
  class Formatter

    def initialize(stats)
      @stats = stats
      s = stats.max_by {|stat| stat[:site].length}
      @site_max_width = s[:site].length + 1
    end

    def formatted!
      return @formatted if @formatted
      header = header_format % ["Site", "IP", "Average", "Stddev", "Loss"]
      rows = [header, "-" * header.length]
      rows += @stats.map {|stat| format_row(stat)}
      @formatted = rows.join("\n")
    end

    def display!(verbose)
      sort!
      puts formatted! if verbose
      puts @stats.first[:server]
    end

    private

    def almost_same?(f1, f2, tolerence)
      (f1 - f2).abs <= tolerence
    end

    # ensure both s1 and s2 are valid hash
    def compare(s1, s2)
      return -1 unless s1[:status] == 0
      return 1 unless s2[:status] == 0
      if almost_same?(s1[:avg], s2[:avg], 15) &&
          almost_same?(s1[:stddev], s2[:stddev], 10)
        s1[:loss] <=> s2[:loss]
      else
        s1[:avg] <=> s2[:avg]
      end
    end

    def sort!
      return if @sorted
      @stats.sort! {|s1, s2| compare(s1, s2)}
      @sorted = true
    end

    def header_format
      "%#{@site_max_width}s   %-16s%8s  %6s   %6s"
    end

    def row_format
      "%#{@site_max_width}s  %16s %8.2f  %6.2f  %6.2f%s"
    end

    def format_row stat
      row_format % [stat[:site], format_ip(stat[:ip]), stat[:avg], stat[:stddev], stat[:loss], '%']
    end

    def format_ip ip
      "%-3d.%-3d.%-3d.%-3d" % ip.split(".")
    end

  end
end

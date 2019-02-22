# FastestServer

Find the fastest server via ping.

## Installation

    $ gem install fastest_server

## Usage

The most basic usage is very simple, you may type `fastest` with a sequence of servers[1]:

    $ fastest 5.153.63.162 159.8.223.72 169.38.84.49 169.46.49.132 23.246.195.8
    (after a while)
    23.246.195.8
    
And there're some options available, considered following command:

    $ fastest --file list --count 3 --job 10 --verbose 169.61.108.35

<p align="center"><img src ="img/ping.gif" /></p>

Where,

+ `-f` or `--file` option will load servers ip or uri  (one server per line) from a file named `list`;
+ `-c` or `--count` option specify the maximum number of packets will be sent (default: 10);
+ `-j` or `--job` option specify the maximum number of ping job run at once (default: 8);
+ `-v` or `--verbose` flag enable printing a more useful status and statistic information, otherwise only the fastest 
server will be displayed on the screen.

Noticed that, you can also provide additional servers as parameters, even a `-f` or `--file` option has been set.

## Disclaim

[1] The ip address all come from [lifesize](https://www.lifesize.com/en/app-help/admin/get-started/ip-address-list) 
for test purpose only.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/DeathKing/fastest_server.

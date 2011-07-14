module BigTuna
  class Hooks::Irc < Hooks::Base
    NAME = "irc"

    def build_still_passes(build, config)
      project = build.project
      Delayed::Job.enqueue(Job.new(config, "New build in '#{project.name}' STILL PASSES (#{build_url(build)})"))
    end

    def build_fixed(build, config)
      project = build.project
      Delayed::Job.enqueue(Job.new(config, "New build in '#{project.name}' FIXED (#{build_url(build)})"))
    end

    def build_still_fails(build, config)
      project = build.project
      Delayed::Job.enqueue(Job.new(config, "New build in '#{project.name}' STILL FAILS (#{build_url(build)})"))
    end

    def build_failed(build, config)
      project = build.project
      Delayed::Job.enqueue(Job.new(config, "New build in '#{project.name}' FAILED (#{build_url(build)})"))
    end

    class Job
      def initialize(config, message)
        @config = config
        @message = message
      end

      def perform
        # Sometime going procedural is the simpler
        require 'socket'
        s= TCPSocket.open(@config[:server], @config[:port] || 6667)
        s.puts "PASS #{@config[:password]}" if @config[:password]
        puts "PASS #{@config[:password]}" if @config[:password]
        s.puts "NICK #{@config[:user_name]}"
        puts "NICK #{@config[:user_name]}"
        s.puts "USER #{@config[:user_name]} 0 * :#{@config[:user_name]}"
        puts "USER #{@config[:user_name]} 0 * :#{@config[:user_name]}"
        sleep 12
        puts s.recv 1000
        s.puts "JOIN :#{@config[:room]}"
        puts "JOIN :#{@config[:room]}"
        sleep 7
        puts s.recv 1000
        s.puts "PRIVMSG #{@config[:room]} :#{@message}"
        puts "PRIVMSG #{@config[:room]} :#{@message}"
        s.puts "PART :#{@config[:room]}"
        puts "PART :#{@config[:room]}"
        s.puts "QUIT"
        puts "QUIT"
        puts s.gets until s.eof?
      end

    end
  end
end

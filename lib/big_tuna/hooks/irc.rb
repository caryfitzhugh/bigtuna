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
        msg = @message
        config = @config
        bot = Cinch::Bot.new do
          configure do |c|
            c.nick = config[:user_name]
            c.password = config[:password]
            c.server = config[:server]
            c.port = config[:port]
            c.channels = [config[:room]]
          end

          on :join do |m, e|
            m.reply msg
            bot.quit
          end
        end
        bot.start
      end

    end
  end
end

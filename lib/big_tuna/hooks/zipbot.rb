require 'net/http'
require 'uri'

module BigTuna
  class Hooks::Irc < Hooks::Base
    NAME="bigtuna"

    def description(build)
      "#{build.project.name}:#{build.commit.slice(0..6)}:#{build.author} #{build.commit_message.split("\n").slice(0..80)}"
    end

    def build_started(build, config)
      Delayed::Job.enqueue(Job.new(config, build, :started))
    end
    def build_still_passes(build, config)
      Delayed::Job.enqueue(Job.new(config, build, :passed))
    end

    def build_fixed(build, config)
      Delayed::Job.enqueue(Job.new(config, build, :passed))
    end

    def build_still_fails(build, config)
      Delayed::Job.enqueue(Job.new(config, build, :failed))
    end

    def build_failed(build, config)
      Delayed::Job.enqueue(Job.new(config, build, :failed))
    end

    class Job
      def initialize(config, build, state)
        @config = config
        @build = build
        @state = state
      end

      def perform
        host = URI.parse(@config.host)
        host.path = "/testing/#{@build.project.vcs_branch}/#{@state.to_s}"
        res = Net::HTTP.post_form(host)
      end
  end
end

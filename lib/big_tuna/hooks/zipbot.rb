require 'net/http'
require 'uri'

module BigTuna
  class Hooks::ZipBot < Hooks::Base
    NAME="zipbot"

    def build_started(build, config)
      enqueue(config, build, :started)
    end
    def build_still_passes(build, config)
      enqueue(config, build, :passed)
    end

    def build_fixed(build, config)
      enqueue(config, build, :passed)
    end

    def build_still_fails(build, config)
      enqueue(config, build, :failed)
    end

    def build_failed(build, config)
      enqueue(config, build, :failed)
    end

    class Job
      def initialize(config, build, state)
        @config = config
        @build = build
        @state = state
      end

      def perform
        host = URI.parse(@config['host'])
        host.path = "/testing//#{@build.project.vcs_branch}/#{@state.to_s}"
        body = {:repo => @build.project.vcs_source,
                :build=>@build.attributes,
                :project => @build.project.attributes}
        BigTuna.logger.info("POSTING: #{host.to_s}, => #{body}")
        res = Net::HTTP.post_form(host,body)
      end
    end

    private
    def enqueue(config, build, state)
      BigTuna.logger.info "Zipbot: #{config}, #{build}, #{state}"
      Delayed::Job.enqueue(Job.new(config, build, state))
    end
  end
end

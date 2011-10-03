module BigTuna
  class Hooks::Mailer < Hooks::Base
    NAME = "mailer"

    def build_fixed(build, config)
      recipients = config["recipients"]
      Sender.delay.build_fixed(build, recipients) unless recipients.blank?
    end

    def build_still_fails(build, config)
      recipients = config["recipients"]
      Sender.delay.build_still_fails(build, recipients) unless recipients.blank?
    end

    def build_failed(build, config)
      recipients = config["recipients"]
      Sender.delay.build_failed(build, recipients) unless recipients.blank?
    end

    def build_still_passes(build, config)
      project = build.project
      Sender.delay.build_still_passes(build, recipients) unless recipients.blank?
    end


    class Sender < ActionMailer::Base
      self.append_view_path("lib/big_tuna/hooks")
      default :from => ActionMailer::Base.smtp_settings[:username] || "set_username_in_email.yml"

      def build_still_passes(build, recipients)
        @build = build
        @project = @build.project
        mail(:to => recipients, :subject => "PASS: '#{@build.display_name}' in '#{@project.name}'") do |format|
          format.text { render "mailer/build_passes" }
        end
      end
      def build_failed(build, recipients)
        @build = build
        @project = @build.project
        mail(:to => recipients, :subject => "FAIL: '#{@build.display_name}' in '#{@project.name}'") do |format|
          format.text { render "mailer/build_failed" }
        end
      end

      def build_still_fails(build, recipients)
        @build = build
        @project = @build.project
        mail(:to => recipients, :subject => "FAIL: '#{@build.display_name}' in '#{@project.name}'") do |format|
          format.text { render "mailer/build_still_fails" }
        end
      end

      def build_fixed(build, recipients)
        @build = build
        @project = @build.project
        mail(:to => recipients, :subject => "PASS: '#{@build.display_name}' in '#{@project.name}'") do |format|
          format.text { render "mailer/build_fixed" }
        end
      end
    end
  end
end

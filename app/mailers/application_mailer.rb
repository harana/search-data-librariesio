# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "Libraries <notifications@harana.dev>"
  layout "mailer"
end

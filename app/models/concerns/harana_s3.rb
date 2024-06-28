# frozen_string_literal: true

module HaranaS3
  extend ActiveSupport::Concern

  def push_project_to_s3_async
    HaranaS3PushProjectWorker.perform_async(id)
  end

end
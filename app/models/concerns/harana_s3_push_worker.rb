# frozen_string_literal: true

module OpenaiContents
  extend ActiveSupport::Concern

  def push_project_to_s3_async
    HaranaS3PushProjectWorker.perform_async(id)
  end

  def push_sitemaps_to_s3_async
    HaranaS3PushSitemapsWorker.perform_async(id)
  end

end
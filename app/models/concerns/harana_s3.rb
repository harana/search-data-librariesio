# frozen_string_literal: true

module HaranaS3
  extend ActiveSupport::Concern

  def push_project_to_s3_async
    HaranaS3PushProjectWorker.perform_async(id)
  end

  def push_project_to_s3_async_given_openai
    id = OpenaiContent.find(id).project_id
    HaranaS3PushProjectWorker.perform_async(id)
  end

end
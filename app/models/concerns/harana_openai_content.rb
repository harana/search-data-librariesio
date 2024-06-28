# frozen_string_literal: true

module HaranaOpenaiContents
  extend ActiveSupport::Concern

  def update_openai_content_async
    HaranaOpenaiContentWorker.perform_async(id)
  end

end
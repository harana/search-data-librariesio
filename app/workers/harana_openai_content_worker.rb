# frozen_string_literal: true

require "httparty"

class HaranaOpenaiContentWorker
  include HTTParty
  include Sidekiq::Worker

  sidekiq_options queue: :critical, retry: 3

  def perform(project_id)
    project = Project.find(project_id)

    return if OpenaiContent.find_by(project_id: project_id)

    prompt = <<-PROMPT
      given a "#{project.platform}" library named "#{project.name}". I want a JSON document with the following fields:
    - description: 150-word description in multiple paragraphs without repeating the library name or type
    - use cases: array of 5 use cases for how this library could be used
    - keywords: array of 5 single word keywords that represent this library
    - example code: sample code for how this library could be used
    - questions: array of 20 questions/answers that a user might commonly ask regarding this library. Each answer should be 2-3 sentences.
      The audience for this is software engineers so the tone should be factual. Keep the language basic with less salesy words like seamlessly.
    PROMPT

    body = {
      model: "gpt-3.5-turbo",
      prompt: prompt,
      max_tokens: 1000,
      temperature: 0.5,
    }
  
    options = {
      headers: {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{ENV.fetch("harana_openai_key", nil)}",
      }
    }
  
    azure_endpoint = "https://api.openai.com/v1/completions"
    response = HTTParty.post(azure_endpoint, body: body.to_json, **options)
    if response.success?
      Rails.logger.error(response.parsed_response)
    else
      { error: response.parsed_response["error"], status_code: response.code }
    end
  end
end
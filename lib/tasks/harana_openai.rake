# frozen_string_literal: true

namespace :harana_openai do

  desc "Fetches OpenAI content for each project"
  task fetch_content: :environment do
    perform(Project.first.id)
    # Project.find_each do |project|
    #   Rails.logger.info("Fetching OpenAI content for #{project.name}")
    #   HaranaOpenAiContentWorker.perform_async(project)
    # end
  end

  def perform(project_id)
    project = Project.find(project_id)

    return if OpenaiContent.find_by(project_id: project_id)

    prompt = <<-PROMPT
    given "#{project.platform}" library named "#{project.name}" I want JSON with these fields:
    - about: 150-word description in multiple paragraphs (any newlines seperated with <br>). Do not mention "#{project.name}".
    - use_cases: 5 use cases
    - example_code: sample code with escaped tabs
    - faqs: 20 questions/answers that a user might commonly ask. Each answer should be 2-3 sentences.
      Audience is software engineers. Keep language basic. Don't include start/end JSON tokens.
    PROMPT

    OpenAI.configure do |config|
      config.access_token = "3b167f06ef21400eaebe6689ae3a6c8b"
      config.uri_base = "https://harana-data-librariesio.openai.azure.com/openai/deployments/Harana"
      config.api_type = :azure
      config.api_version = "2023-03-15-preview"
      config.log_errors = false
    end

    response = OpenAI::Client.new(request_timeout: 600).chat(
    parameters: {
        model: "gpt-4o",
        messages: [{ role: "user", content: prompt}],
        temperature: 0.7
    })

    content = response.dig("choices", 0, "message", "content")
    
    begin
      json_content = JSON.parse(content)
      OpenaiContent.create!(
        project_id: project_id,
        about: json_content['about'].to_json,
        example_code: json_content['example_code'],
        faqs: json_content['faqs'].to_json,
        tags: json_content['tags'].to_json,
        use_cases: json_content['use_cases'].to_json
      )
      Rails.logger.info("OpenAI content successfully created for project #{project.name}")
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse JSON content: #{e.message}")
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Failed to save OpenAI content: #{e.message}")
    end

  end
end
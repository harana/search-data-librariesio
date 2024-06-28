# frozen_string_literal: true

class HaranaS3PushProjectWorker
  include Sidekiq::Worker

  sidekiq_options queue: :critical, retry: 3

  def perform(project_id)
    project = Project.find(project_id)
    s3 = S3.new

    file = Tempfile.new(project_id.to_s)
    Rails.logger.info("Generating: #{file}")
    FileUtils.mkdir_p(File.dirname(file))
    File.write(file, ERB.new(File.read("app/assets/harana/templates/library.html.erb")).result_with_hash({project: project}))
    s3.save_object(project.file_path, file)

    File.delete(file)
  end
end
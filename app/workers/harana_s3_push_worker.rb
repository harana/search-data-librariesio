# frozen_string_literal: true

require "aws-sdk-s3"

credentials = Aws::Credentials.new(ENV.fetch("harana_aws_access_key", nil), ENV.fetch("harana_aws_secret_key", nil))
@s3 = Aws::S3::Resource.new(region: "ap-southeast-2", credentials: credentials)

class HaranaS3PushWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, lock: :until_executed

  def perform(project_id)
    project = Project.find(project_id)

    
  end
end

# Save a string as an object to the specified S3 bucket
def save_object(bucket, key, content, overwrite: true)
  obj = bucket.object(key)
  if overwrite
    obj.put(body: content)
    puts "Content uploaded to #{obj.public_url}"
  else
    # Only write if the object does not exist
    existing_content = obj.get rescue nil
    if existing_content.nil?
      obj.put(body: content)
      puts "Content uploaded to #{obj.public_url}"
    else
      puts "Content not uploaded because it already exists and overwrite is disabled."
    end
  end
rescue StandardError => e
  puts "Failed to upload content: #{e.message}"
end

# Delete an object from the specified S3 bucket
def delete_object(bucket, key)
  obj = bucket.object(key)
  if obj.delete
    puts "File #{key} deleted successfully."
  else
    puts "Failed to delete file."
  end
rescue StandardError => e
  puts "Failed to delete file: #{e.message}"
end

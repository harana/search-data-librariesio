require "aws-sdk-s3"

module S3Handler
  credentials = Aws::Credentials.new(ENV.fetch("harana_aws_access_key", nil), ENV.fetch("harana_aws_secret_key", nil))
  s3 = Aws::S3::Resource.new(region: "ap-southeast-2", credentials: credentials)
  bucket = s3.bucket("harana-website-haranadev")

  # Save a string as an object to the specified S3 bucket
  def save_object(key, content, overwrite: true)
    obj = bucket.object(key)
    if overwrite
      obj.put(body: content)
      puts "Content uploaded to #{obj.public_url}"
    else
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
  def delete_s3_object(key)
    obj = bucket.object(key)
    if obj.delete
      puts "File #{key} deleted successfully."
    else
      puts "Failed to delete file."
    end
  rescue StandardError => e
    puts "Failed to delete file: #{e.message}"
  end

end
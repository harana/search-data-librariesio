require "aws-sdk-s3"

class S3

  def get_bucket
    credentials = Aws::Credentials.new(ENV.fetch("HARANA_AWS_ACCESS_KEY", nil), ENV.fetch("HARANA_AWS_SECRET_KEY", nil))
    s3 = Aws::S3::Resource.new(region: "ap-southeast-2", credentials: credentials)
    s3.bucket("harana-website-haranadev")
  end

  # Save a string as an object to the specified S3 bucket
  def save_object(key, file, overwrite: true, content_type: "text/html")

    credentials = Aws::Credentials.new(ENV.fetch("HARANA_AWS_ACCESS_KEY", nil), ENV.fetch("HARANA_AWS_SECRET_KEY", nil))
    s3 = Aws::S3::Resource.new(region: "ap-southeast-2", credentials: credentials)
    file_name = File.absolute_path(file)
    bucket = get_bucket

    obj = bucket.object(key)
    if overwrite

      s3.put_object({
        body: file_name, 
        bucket: bucket, 
        key: file_name,
        options: { content_type: content_type }
      })

      puts "Content uploaded to #{obj.public_url}"
    else
      existing_content = obj.get rescue nil
      if existing_content.nil?
      obj.upload_file(file_name, options: { content_type: content_type })
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
    obj = get_bucket.object(key)
    if obj.delete
      puts "File #{key} deleted successfully."
    else
      puts "Failed to delete file."
    end
  rescue StandardError => e
    puts "Failed to delete file: #{e.message}"
  end

end
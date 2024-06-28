require "aws-sdk-s3"

class S3

  def get_client
    credentials = Aws::Credentials.new(ENV.fetch("HARANA_AWS_ACCESS_KEY", nil), ENV.fetch("HARANA_AWS_SECRET_KEY", nil))
    Aws::S3::Client.new(region: "ap-southeast-2", credentials: credentials)
  end

  # Save a string as an object to the specified S3 bucket
  def save_object(key, file, content_type: "text/html")
    client = get_client
    file_name = File.absolute_path(file)

    client.put_object({
      body: IO.read(file_name), 
      bucket: "harana-website-haranadev", 
      key: key,
      content_type: content_type
    })

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
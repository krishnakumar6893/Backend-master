module S3Configration

  def self.upload(file, path)
    file = get_bucket.files.create(
      :key    => path,
      :body   => File.open(file),
      :public => true
    )

    file.present? ? file.public_url : ""
  end

  def self.get_bucket(prefix = nil)
    connection = Fog::Storage.new(DeepType::AWS_CONFIG)

    connection.directories.get(DeepType::AWS_BUCKET, prefix: prefix)
  end
end

module FontliUtil

  # Genrate random secure string with given length
  def self.secure_random length = 16
    SecureRandom.hex(length.to_i)
  end

  # Write given data to specified path
  def self.write_file(path, data_file)
    File.open(path, "wb") { |f| f.write(File.read(data_file)) }
  end

  # Remove the file from given path if exist.
  def self.remove_file path
    File.delete(path) if File.exist?(path)
  end
end

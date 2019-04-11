class EmailAddress
  include Mongoid::Document
  include MongoExtensions
  include Mongoid::Timestamps

  field :address, :type => String
  field :status, :type => String

  validates :address, :status, presence: true
end

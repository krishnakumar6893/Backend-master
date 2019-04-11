class DeviceOs
  include Mongoid::Document
  include Mongoid::Timestamps
  include MongoExtensions

  belongs_to :user, index: true, inverse_of: :devices

  field :name, type: String
end

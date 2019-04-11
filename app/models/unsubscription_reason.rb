class UnsubscriptionReason
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  belongs_to :user

  field :description, type: String

  validates :description, presence: true

  scope :default, -> { where(user_id: nil) }
end

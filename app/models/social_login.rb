class SocialLogin
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include MongoExtensions
  #include Pointable

  PLATFORMS = %w(twitter facebook).freeze

  belongs_to :user, index: true, inverse_of: :social_logins

  field :platform, type: String
  field :extuid, type: String, default: 'default'
  field :image_url, type: String
  field :full_name, type: String
  field :logged_at, type: DateTime

  validates :user_id, :extuid, presence: true

  before_save :set_logged_at

  def self.recent
    desc('logged_at').first
  end

  def self.by_extid(exid)
    social_login = where(extuid: exid.to_s).first
    if social_login.try(:logged_at) && (Time.now.utc - social_login.logged_at) > 10.minute
      social_login.update_attribute(:logged_at, Time.now.utc)
    end
    social_login
  end

  private

  def set_logged_at
    self.logged_at = Time.now.utc
  end
end

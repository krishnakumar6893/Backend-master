require 'uri'
require 'net/http'

class Point
  include Mongoid::Document
  include Mongoid::Timestamps

  LIKE_POINTS = 1
  SOCIAL_LOGIN_POINTS = 5
  COMMENT_POINTS = 1
  FONT_TAG_POINTS = 2
  SHARE_POINTS = 5
  OWNERD_SHARE_POINTS = 5
  ACTIVE_POINTS = 2
  POST_POINTS = 5
  DEEP_TYPE_POINTS = 10

  field :gain_point, :type => Integer, default: 0

  belongs_to :from_user, :class_name => 'User', :inverse_of => :gain_points
  belongs_to :pointable, :polymorphic => true, :index => true

  validates :pointable_id, :pointable_type, :presence => true

  def self.like_points
    LIKE_POINTS
  end

  def self.social_login_points
    SOCIAL_LOGIN_POINTS
  end

  def self.comment_points
    COMMENT_POINTS
  end

  def self.font_tag_points
    FONT_TAG_POINTS
  end

  def self.share_points
    SHARE_POINTS
  end

  def self.ownerd_share_points
    OWNERD_SHARE_POINTS
  end

  def self.active_points
    ACTIVE_POINTS
  end

  def self.post_points
    POST_POINTS
  end

  def self.deep_type_points
    DEEP_TYPE_POINTS
  end
end

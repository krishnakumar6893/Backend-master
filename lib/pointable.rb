# Created at 25/04/2017 by @simranjit
# Desc: Points are calculated and add/miuns to User.points attribute.
# Pointable#get_points_for responsible for deciding Model for add/minus points.
module Pointable

  def self.included(klass)
    super
    klass.class_eval do
      # Sssociations to incuded class
      has_many :points, :as => :pointable, :dependent => :destroy

      after_create :add_point
      after_destroy :negate_point
    end
  end

  private
  def add_point
    # check if like is on own post or not?
    # don't need to add/negate like point on own post
    # self.user_id #==> who is going ot like it
    # self.photo.user_id #==> who is owner of that photo

    # make points record for history
    create_point
  end

  def negate_point
    # #==> who liked it.
    # self.points.select{|x| x.from_user_id == self.user_id}.first.from_user

    point = self.points.select{|x| x.from_user_id == self.user_id}.first
    # if point is nil, no point is asigned to that post.
    if point
      user = point.from_user
      user.update_attributes(points: user.points - point.gain_point)
    end
  end

  def create_point
    gain_point = get_points_for(self.class)
    return if gain_point.zero?
    points.create(from_user_id: user_id, gain_point: gain_point)
    user.update_attributes(points: user.reload.points + gain_point)
  end

  # prevent to give point on its own like to own stuff
  def ownerd_post?
    self.user_id == self.photo.user_id
  end

  def get_points_for(klass)
    point = case klass
            when Like
              Point.like_points # unless ownerd_post?
            when SocialLogin
              Point.social_login_points
            when Comment
              Point.comment_points # unless ownerd_post?
            when FontTag
              Point.font_tag_points # unless ownerd_post?
            when Share
              ownerd_post? ? Point.ownerd_share_points : Point.share_points
            else
              0
            end
    point.to_i
  end
end

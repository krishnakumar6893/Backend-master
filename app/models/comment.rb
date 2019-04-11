class Comment
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include MongoExtensions
  include Pointable

  field :body, :type => String
  field :font_tag_ids, :type => Array
  field :foto_ids, :type => Array  #mentioned photo_ids

  belongs_to :photo, :index => true, :counter_cache => true
  belongs_to :user, :index => true
  has_many :mentions, :as => :mentionable, :dependent => :destroy
  delegate :username, :full_name, :social_name, to: :user
  delegate :points, to: :user, prefix: true

  validates :user_id, :photo_id, :presence => true
  validates :body, :length => { :maximum => 500, :allow_blank => true }, format: { with:  /\A[a-zA-Z0-9\ \.\!\&\@\,\-\#]+\Z/ }
  after_create :populate_mentions
  after_destroy :delete_assoc_font_tags
  include Notifiable

  default_scope lambda { {:where => { :user_id.nin => User.inactive_ids }} }

  class << self
    # delete_comment api finds comment bypassing the assoc photo, though its not recommended.
    def [](cmt_id)
      self.where(:_id => cmt_id).first
    end
  end

  #Overriding the notification method
  #notify the publisher, all users in comment thread
  #make sure the mentioned usrs are ignored.
  def notif_target_user_id
    owner = [self.photo.user_id]
    commented_usrs = self.photo.comments.only(:user_id).collect(&:user_id)
    mentioned_usrs = self.mentions.only(:user_id).collect(&:user_id)
    (owner + commented_usrs - mentioned_usrs).flatten.uniq
  end

  # return a custom font collection(w/ coords) tagged with this comment.
  def fonts
    return [] if self.font_tag_ids.blank?
    return @fonts unless @fonts.nil? # compute once per instance
    fnt_tags = FontTag.where(:_id.in => self.font_tag_ids).to_a
    fnt_ids = fnt_tags.collect(&:font_id).uniq
    fnts = Font.where(:_id.in => fnt_ids).to_a.group_by(&:id)
    @fonts = fnt_tags.collect do |ft|
      f = fnts[ft.font_id].first
      OpenStruct.new(f.attributes.update(
        :id => f.id,
        :tags_count => f.tags_count,
        :my_agree_status => f.my_agree_status,
        :img_url => f.img_url,
        :my_fav? => f.my_fav?,
        :coords => ft.coords) )
    end
  end

  def user_url_thumb
    @usr ||= self.user
    @usr.url_thumb
  end

  def notif_context
    ['has commented']
  end

  def fotos
    return [] if self.foto_ids.blank?
    Photo.where(:_id.in => self.foto_ids).only(:id, :data_filename).to_a
  end

private

  def populate_mentions
    mnts = Photo.check_mentions_in(self.body)
    mnts.each { |hsh| self.mentions.create(hsh) }
    true
  end

  def delete_assoc_font_tags
    return true unless self.font_tag_ids.present?
    fnt_tgs = FontTag.where(:_id.in => self.font_tag_ids).to_a
    # destroy the font all together if that's the last tag on it.
    fnt_tgs.each { |ft| ft.font.tags_count == 1 ? ft.font.destroy : ft.destroy }
    true
  end
end

module UsersHelper
  def last_activity(user)
    user.photos.last.created_dt
  end
end

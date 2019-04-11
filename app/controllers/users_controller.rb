class UsersController < AdminController
  before_filter :find_user

  def show
    @photos = @user.photos.order_by(sort_column => sort_direction)
    @photos = paginate_array(@photos.to_a)
  end

  def add_photo
    @photo = @user.photos.new
  end

  def create_photo
    session[:user_id] = @user.id
    params[:photo][:collection_names] = params[:photo][:collection_names].try { |tags| tags.split(',') }
    photo = @user.photos.new(params[:photo].merge(created_at: Time.now.utc))

    opts = photo.save ? { notice: 'Photo uploaded successfully' } : { alert: photo.errors.full_messages.join('<br/>') }
    session[:user_id] = nil
    redirect_to admin_user_path(@user), opts
  end

  private

  def find_user
    @user = User.find(params[:id])
  end
end

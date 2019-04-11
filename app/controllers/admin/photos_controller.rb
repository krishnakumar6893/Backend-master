class Admin::PhotosController < AdminController
  before_filter :find_photo, except: [:unapproved, :spam, :deep_type_requests]

  def update
    params[:photo][:collection_names] = params[:photo][:collection_names].try { |tags| tags.split(',') }
    @photo.collections = []
    @photo.attributes = params[:photo]
    opts = @photo.save ? { notice: 'Photo updated successfully' } : { alert: photo.errors.full_messages.join('<br/>') }
  end

  def unapproved
    @photos = Photo.unapproved.order_by(sort_column => sort_direction)
    @photos = @photos.where(user_id: params[:user_id]) if params[:user_id].present?
    @photos = paginate_array(@photos.to_a)
  end

  def approve
    if @photo.update_attributes(approved: true, approved_at: Time.now.utc)
      flash[:notice] = "Photo approved successfully."
    else
      flash[:alert] = "Photo is not approved."
    end
  end

  def spam
    @photos = Photo.unscoped.where(deleted: true).order_by(sort_column => sort_direction)
    @photos = paginate_array(@photos.to_a)
  end

  def deep_type_requests
    @deep_type_requests = DeepType.all.order_by(sort_column => sort_direction)
    @deep_type_requests = paginate_array(@deep_type_requests.to_a)
  end

  private

  def find_photo
    @photo = Photo.find(params[:id])
  end
end

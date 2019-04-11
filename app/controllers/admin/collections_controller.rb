class Admin::CollectionsController < AdminController
  before_filter :admin_required, except: :fetch_names
  before_filter :find_collection, except: [:index, :create, :fetch_names]

  def index
    @collections = Collection.all.to_a
  end

  def create
    opts = params[:collection]
    collection = Collection.new(name: opts[:name], description: opts[:description])
    if collection.save
      flash[:notice] = 'Created successfully'
    else
      flash[:alert] = collection.errors.full_messages.join('<br/>')
    end
    redirect_to admin_collections_path
  end

  def update
    if params[:cover_photo].present?
      photo = Photo.where(id: @collection.cover_photo_id).first || Photo.new
      photo.data = params.delete(:cover_photo)
      @collection.cover_photo_id = photo.id if photo.save
    end

    if @collection.update_attributes(params[:collection])
      redirect_to admin_collections_path, notice: 'Updated successfully'
    else
      render :edit
    end
  end

  def destroy
    @collection.try(:destroy)
    redirect_to admin_collections_path, notice: 'Deleted successfully'
  end

  def activate
    if @collection.update_attribute(:active, true)
      flash[:notice] = 'Activated successfully'
    else
      flash[:alert] = 'Activation failed'
    end
    redirect_to admin_collections_path
  end

  def fetch_names
    render json: Collection.pluck(:name)
  end

  def show
    @photos = @collection.photos.order_by(sort_column => sort_direction)
    @photos = paginate_array(@photos.to_a)
  end

  def set_cover_photo
    if @collection.update_attribute(:cover_photo_id, params[:photo_id])
      flash[:notice] = 'Cover photo is set successfully'
    else
      flash[:alert] = 'Cover photo is not assigned'
    end

    redirect_to admin_collection_path(@collection)
  end

  private

  def find_collection
    @collection = Collection.find(params[:id])
  end
end

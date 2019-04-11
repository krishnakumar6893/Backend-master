class AdminController < ApplicationController
  skip_before_filter :login_required # skip the regular login check
  before_filter :admin_required, except: [:user_stats] # use http basic auth
  helper_method :sort_column, :sort_direction

  def index
    @admin_presenter = AdminPresenter.new
  end

  def users
    @users = User.non_admins.order_by(sort_column => sort_direction)
    @users = @users.search(params[:search], sort_column, sort_direction) if params[:search].present?
    @suspend_user = true
    @delete_user = true
    @users = paginate_array(@users.to_a)
  end

  def suspend_user
    @res = User.where(_id: params[:id]).first.update_attribute(:active, false)
    opts = @res ? { notice: 'User account suspended.' } : { alert: 'Couldn\'t suspend. Please try again!' }
    redirect_to users_admin_path, opts
  end

  def delete_user
    @res = User.unscoped.where(_id: params[:id]).first.destroy
    opts = @res ? { notice: 'User account deleted.' } : { alert: 'Couldn\'t delete. Please try again!' }
    redirect_to users_admin_path, opts
  end

  def suspended_users
    @users = User.unscoped.where(active: false).order_by(sort_column => sort_direction)
    @title = 'Suspended Users'
    params[:search] = 'Not Implemented'
    @activate_user = true
    @delete_user = true
    @users = paginate_array(@users.to_a)
    render :users
  end

  def activate_user
    @res = User.unscoped.where(_id: params[:id]).first.update_attribute(:active, true)
    opts = @res ? { notice: 'User account activated.' } : { alert: 'Couldn\'t activate. Please try again!' }
    redirect_to users_admin_path, opts
  end

  def photos
    @fotos = Photo.approved
    @fotos = @fotos.for_homepage if params[:home].to_s == 'true'
    @fotos = @fotos.where(user_id: params[:user_id]) if params[:user_id].present?
    @fotos = @fotos.order_by(sort_column => sort_direction)
    @fotos = @fotos.search(params[:search], sort_column, sort_direction) if params[:search].present?

    if !params[:user_id].to_s.strip.blank?
      @select_photo = true
    elsif params[:home].to_s == 'true'
      @title = 'Homepage Photos'
      @unselect_photo = true
    else
      @select_photo = true
    end
    @fotos = paginate_array(@fotos.to_a)
  end

  def flagged_users
    params[:sort] ||= 'user_flags_count'
    @users = User.unscoped.where(:user_flags_count.gte => User::ALLOWED_FLAGS_COUNT).order_by(sort_column => sort_direction)
    @title = 'Flagged Users'
    params[:search] = 'Not Implemented'
    @unflag_user = true
    @delete_user = true
    @users = paginate_array(@users.to_a)
    render :users
  end

  def unflag_user
    usr = User.unscoped.where(_id: params[:id]).first
    res = usr.user_flags.destroy_all
    res &&= usr.update_attribute(:user_flags_count, 0)
    opts = res ? { notice: 'User account unflagged.' } : { alert: 'Couldn\'t unflag. Please try again!' }
    redirect_to flagged_users_admin_path, opts
  end

  def flagged_photos
    params[:sort] ||= 'flags_count'
    @fotos = Photo.unscoped.where(:flags_count.gte => Photo::ALLOWED_FLAGS_COUNT).order_by(sort_column => sort_direction)
    @title = 'Flagged Photos'
    params[:search] = 'Not Implemented'
    @unflag_photo = true
    @fotos = paginate_array(@fotos.to_a)
    render :photos
  end

  def unflag_photo
    photo = Photo.unscoped.where(_id: params[:id]).first

    if photo && photo.flags.destroy_all
      @res = photo.update_attribute(:flags_count, 0)
    end
  end

  def sos
    fetch_sos
    @fotos = @fotos.search(params[:search], sort_column, sort_direction) if params[:search].present?
    @fotos = paginate_array(@fotos.to_a)
    render :photos
  end

  def approve_sos
    @res = Photo[params[:photo_id]].update_attribute(:sos_approved, true) rescue false
  end

  def delete_photo
    @res =  Photo.unscoped.where(_id: params[:id]).first.destroy rescue false
  end

  def select_photo
    unselect = params[:select].to_s == 'false'
    @res =  Photo[params[:id]].update_attribute(:show_in_homepage, !unselect) rescue false
  end

  def popular_users
    @users = User.recommended
  end

  def popular_photos
    @photos = Photo.popular
  end

  def popular_fonts
    fonts = Font.api_recent
    @photos = fonts.collect do |fnt|
      Font.tagged_photos_popular(fnt.family_id).to_a
    end.flatten
    @font_page = true
    render action: 'popular_photos'
  end

  def select_for_header
    klass = whitelisted_class.constantize
    obj = klass.find(params[:id])
    obj.show_in_header = params[:status] == 'true'
    obj.save! && render(nothing: true)
  end

  def expire_popular_cache
    Stat.expire_popular_cache!
    redirect_to :back
  end

  def update_stat
    Stat.current.update_attributes(app_version: params[:version])
    redirect_to admin_path
  end

  def send_push_notifications
    if params[:message].blank?
      flash.now[:alert] = 'Message can\'t be blank' if request.post?
    else
      users = User.non_admins.where(:iphone_token.ne => nil)
      users.each do |user|
        opts = { :badge => user.notifications.unread.count, :alert => params[:message], :sound => true }
        APN.notify_async(user.iphone_token, opts)
      end
      redirect_to '/admin', :notice => "Notified #{users.length} users."
    end
  end

  def users_statistics
  end

  def user_stats
    result = params[:platform].present? ? Hash[users_data(params[:platform]).sort] : {}
    render json: result
  end

  def top_contributors
    sort_by   = params[:sort] || 'photos_count'
    direction = params[:direction] || 'desc'

    @top_contributors = User.non_admins.where(:photos_count.gt => 0).order_by(sort_by => direction).limit(100)
    @top_contributors = @top_contributors.search(params[:search]) if params[:search].present?

    if request.format.csv?
      send_data top_contributors_csv, type: 'text/csv', filename: 'top_contributors.csv'
    else
      @top_contributors = Kaminari.paginate_array(@top_contributors.to_a).page(params[:page]).per(25)
    end
  end

  private

  def sort_column
    params[:sort].blank? ? 'created_at' : params[:sort]
  end

  def sort_direction
    params[:direction].blank? ? 'desc' : params[:direction]
  end

  def users_data(platform)
    platform = nil if platform == 'email'
    users = User.order_by(created_at: :asc).collection.
                  aggregate({ '$match' => { admin: false, platform: platform } },
                            { '$group' => { _id: { 'month' => { '$month' => '$created_at' },
                                  'year' => { '$year' => '$created_at' } }, 'count' => { '$sum' => 1 } } })
    {}.tap do |h|
      users.each do |user|
        year = user['_id']['year']
        h[year] ||= {}
        h[year]['data'] ||= []
        h[year]['total_count'] ||= 0
        h[year]['data'] << [months_list[user['_id']['month'] - 1], user['count']]
        h[year]['total_count'] += user['count']
      end
      h.each do |_key, val|
        val['data'].sort! do |a, b|
          months_list.index(a.first) <=> months_list.index(b.first)
        end
      end
      active_years = User.collection.aggregate({ '$group' => { _id: { year: { '$year' => '$created_at' } } } }).collect { |u| u['_id']['year'] }
      (active_years - h.keys).each do |year|
        h[year] = {}
      end
    end
  end

  def months_list
    %w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
  end

  def top_contributors_csv
    CSV.generate(headers: true) do |csv|
      csv << ['Username', 'Full Name', 'Email', 'Photos', 'Platform', 'Flag Count', 'Avatar', 'Created At']

      @top_contributors.each do |user|
        full_name = view_context.valid_string(user.full_name)
        csv << [user.username, full_name, user.email, user.photos_count, user.platform, user.user_flags_count, user.url_thumb, user.created_dt]
      end
    end
  end

  def whitelisted_class
    return params[:modal] if %w(User Photo).include? params[:modal]

    raise StandardError, 'unexpected request!'
  end

  def fetch_sos
    if params[:req] == 'true'
      @title = 'SoS photos waiting for approval'
      @fotos = Photo.sos_requested
      params[:sort] ||= 'sos_requested_at'
    else
      @title = 'SoS photos'
      @fotos = Photo.sos_approved
      params[:sort] ||= 'sos_approved_at'
    end
  end

  def paginate_array(data)
    Kaminari.paginate_array(data).page(params[:page])
  end
end

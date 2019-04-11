require 'auth_client'
require 'storify_client'

class WelcomeController < ApplicationController
  include AuthClient
  skip_before_filter :login_required
  skip_before_filter :set_current_controller, :only => [:keepalive]

  layout :select_layout

  def keepalive
    render :text => 'Success'
  end

  def index
    redirect_to(feeds_url) && return if logged_in?
    @story   = StorifyStory.random_story
    @popular = Photo.for_homepage.only(:id,:data_filename).to_a
    @homepage, @meta_title = true, 'Home'
  end

  def login
    return if request.get?
    self.send format('%s_login', params[:platform])
  end

  def api_doc
    render 'api_doc', :layout => false
  end

  def unsubscribe
    @user = User.where(id: params[:id]).last
    @user.update_attribute(:unsubscribed, true)
    return if request.get?
    @user.update_attribute(:unsubscription_reason, params[:reason_id]) if params[:reason_id].present?
    UnsubscriptionReason.create(user_id: @user.id, description: params[:description]) if params[:description].present?
    redirect_to root_path
  end

  private

  def default_login
    uname, pass = [params[:username], params[:password]]
    if uname.blank? || pass.blank?
      flash.now[:alert] = 'Username or Password is blank!'
      return false
    end
    u = User.login uname, pass
    unless u.nil?
      session[:user_id] = u.id
      redirect_to feeds_url
    else
      flash.now[:alert] = 'Invalid username or password!'
    end
  end

  def select_layout
    if [:login, :unsubscribe].include?(params[:action].to_sym)
      'plain'
    else
      'application'
    end
  end
end

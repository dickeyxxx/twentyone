class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :require_login
  rescue_from FbGraph::Exception, :with => :fbexception

  def fbexception
    @current_user.facebook_access_token = nil
    @current_user.save
    if @current_user.facebook_identifier
      redirect_to auth_facebook_path
    else
      redirect_to facebook_link_path
    end
  end

protected
  def fbuser
    unless @current_user
      return nil
    end
    access_token = @current_user.facebook_access_token
    fbuser = FbGraph::User.me(access_token).fetch
  end

  def current_user
    @current_user ||= User.find_by_id(session[:user_id])
  end

  def logged_in?
    !!current_user
  end

  helper_method :current_user, :logged_in?, :fb_user

  def require_login
    unless logged_in?
      redirect_to :login
    end
  end

  def require_admin
    unless @current_user.admin?
      flash[:error] = "This page is available to administrators only"
      redirect_to root_path
    end
  end
end

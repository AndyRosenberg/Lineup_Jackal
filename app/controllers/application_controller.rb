class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?, :require_user, :correct_user?

  def home
  end

  def players
    @players ||= Statistic.everything.sort {|a, b| b['projected'].to_i - a['projected'].to_i}.first(500)
  end

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def logged_in?
    !!current_user
  end

  def require_user
    if !logged_in?
      flash[:error] = "Must be logged in to do that."
      redirect_to login_path
    end
  end

  def correct_user?(obj)
    current_user && (obj.user == current_user)
  end
end

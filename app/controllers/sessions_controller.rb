class SessionsController < ApplicationController
  def create
    user = User.find_by(username: params[:username])
    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      flash[:notice] = "Login successful"
      redirect_to lineups_path
    else
      flash[:error] = "There's something wrong with your credentials"
      redirect_to login_path
    end
  end

  def new; end

  def destroy
    reset_session
    flash[:notice] = "Logged out."
    redirect_to home_path
  end
end
class UsersController < ApplicationController
  def index; end

  def create
    @user = User.new(user_params)

    if @user.save
      session[:user_id] = @user.id
      flash[:notice] = "You are registered. Set your first lineup!"
      redirect_to new_lineup_path
    else
      flash[:error] = "Registration failed. Please try again."
      redirect_to new_user_path
    end
  end

  def new
    @user ||= User.new
  end

  def show; end
  def edit; end
  def update; end
  def destroy; end

  private
  def user_params
    params.require(:user).permit(:email, :username, :password)
  end
end
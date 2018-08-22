class UsersController < ApplicationController
  before_action :require_user, only: [:edit, :update]
  before_action :access_denied?, only: [:edit, :update]

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

  def edit
    @user = User.find(params[:id])
  end

  def update 
    @user = User.find(params[:id])
    if @user.update(user_params)
      flash[:notice] = "Updated!"
    else
      flash[:error] = "There was an issue."
    end

    redirect_to edit_user_path(@user)
  end

  def destroy; end

  def forgot; end

  def validate_forgot
    @user = User.find_by(email: params[:email])
    if @user
      params.permit!
      @user.token = SecureRandom.urlsafe_base64(15)
      @user.sent_time = DateTime.now
        if @user.save
          Resetter.reset(@user).deliver_now
          flash[:notice] = "Please check your email for the reset link."
        else
          flash[:error] = "Something went wrong, please try again."
        end
    else
      flash[:error] = "No user found with email #{params[:email]}."
    end

    redirect_to forgot_users_path
  end

  def reset 
    @user = User.find_by(token: params[:id])
    opened_time = DateTime.now
    unless @user && @user.sent_time > opened_time.days_ago(1)
      flash[:error] = "Please try again."
      redirect_to forgot_users_path 
    end
  end

  def validate_reset
    @user = User.find_by(token: params[:id])

    if @user
      params.permit!
      @user.password = params[:password]
      if @user.save
        @user.update_column(:token, nil)
        @user.update_column(:sent_time, nil)
        flash[:notice] = "Password successfully reset."
        redirect_to login_path
      else
        flash[:error] = "There was an issue. Please try again."
        redirect_to reset_user_path(@user.token)
      end
    else
      flash[:error] = "There was an issue. Please try again."
      redirect_to forgot_users_path
    end
  end

  private
  def user_params
    params.require(:user).permit(:email, :username, :password)
  end

  def access_denied?
    unless params[:id].to_i == current_user.id
      flash[:error] = "Access Denied"
      redirect_to home_path 
    end
  end
end
require 'rails_helper'

describe LineupsController do
  add_user

  context "pre-login" do
    it "redirects" do
      get :index
      expect(response).to redirect_to login_path
    end
  end

  context "after-login" do
    before do
      session[:user_id] = andy.id
    end

    it "loads index" do
      get :index
      expect(response).to render_template :index
    end
  end
end
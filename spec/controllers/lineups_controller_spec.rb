require 'rails_helper'

describe LineupsController do
  add_user

  context "pre-login" do
    describe "GET index" do
      it "redirects to login" do
        get :index
        expect(response).to redirect_to login_path
      end
    end
  end

  context "after-login" do
    before do
      session[:user_id] = andy.id
    end

    describe "GET index" do
      it "loads index" do
        get :index
        expect(response).to render_template :index
      end
    end
  end
end
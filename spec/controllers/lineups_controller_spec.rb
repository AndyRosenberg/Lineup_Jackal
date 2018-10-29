require 'rails_helper'

describe LineupsController do
  add_user
  add_lineup

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
      assign_lineup(andy, my_lineup)
    end

    describe "GET index" do
      it "loads index" do
        get :index
        expect(response).to render_template :index
      end

      it "assigns lineups" do
        get :index
        expect(assigns(:lineups).first).to be_instance_of(Lineup)
      end
    end

    describe "GET show" do
      it "has no starters" do
        get :show, params: { id: my_lineup.token }
        expect(assigns(:starters).size).to eq(0)
      end

      it "now has one starter" do
        luck = Player.fake(Statistic.find_player('1932'))
        im_luck = Player.fake_show(JSON.parse(luck.to_json))
        im_luck.lineup_id = my_lineup.id
        im_luck.status = "starter"
        im_luck.save!
        get :show, params: { id: my_lineup.token }
        expect(assigns(:starters).size).to eq(1)
      end
    end
  end
end
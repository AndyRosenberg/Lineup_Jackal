require 'rails_helper'
require 'spec_helper'

def add_user
  let(:andy) { Fabricate(:user) }
end

def add_session
  add_user
  session[:user_id] = andy.id
end

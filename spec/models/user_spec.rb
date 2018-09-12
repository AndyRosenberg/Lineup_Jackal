require 'rails_helper'

describe User do
  add_user

  it 'works' do
    expect(andy).to be
    expect(andy.username).to be
    expect(andy.email).to be
    expect(andy.password).to be
    expect(andy.password.length).to be >= 7
  end
end
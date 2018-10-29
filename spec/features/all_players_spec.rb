require 'rails_helper'

feature "Change filter in flex index" do
  scenario "Default" do
    visit all_players_path
    expect(page).to have_content("Aaron Rodgers")
    expect(page).to have_content("Todd Gurley")
  end

  scenario "Switch to QB" do
    visit all_players_path(pos: "QB")
    expect(page).to have_content("Aaron Rodgers")
    expect(page).to have_no_content("Todd Gurley")
  end

  scenario "Switch to RB" do
    visit all_players_path(pos: "RB")
    expect(page).to have_no_content("Aaron Rodgers")
    expect(page).to have_content("Todd Gurley")
  end
end
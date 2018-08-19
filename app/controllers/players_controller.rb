class PlayersController < ApplicationController
  before_action :require_user
  before_action :find_lineup

  def index
    everything ||= Statistic.everything.sort {|a, b| b['projected'].to_i - a['projected'].to_i}.first(500)
    @all_players ||= @lineup.filter_players(everything)
  end

  def create
    params.require(:player).permit!
    player = Player.fake_show(params[:player])
    player.status = "bench"
    player.lineup_id = params[:lineup_id]
    @button = "#button-#{player.ff_id}".html_safe
    render "added" if player.save
  end

  def show; end

  def destroy
    player = Player.find(params[:id])
    @article = "#edit-#{player.ff_id}".html_safe
    player.delete
    render "players/delete"
  end

  private
  def find_lineup
    @lineup = Lineup.find(params[:lineup_id])
  end
end
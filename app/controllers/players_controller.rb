class PlayersController < ApplicationController
  before_action :require_user, except: [:show, :flex_index, :search]
  before_action :find_lineup, except: [:show, :flex_index, :flex_create, :search]
  before_action :validate_pos, only: [:index, :flex_index, :flex_create, :search]

  def index
    @everything = Statistic.ev_pos(@pos).first(500)
    @all_players = @lineup.filter_players(@everything)
    fresh_when(@pos && @all_players)
    @type = @lineup.league_type
  end

  def flex_index
    @players = Statistic.ev_pos(@pos).first(300)
    fresh_when(@pos && current_user && @players)
  end

  def search
    @query = params[:query]

    if @query.blank?
      @players = []
      flash[:error] = "No players matched your search."
    else
      @players = Statistic.ev_pos(@pos).first(500)
      @players = @players.select { |pl| pl['full_name'].downcase.include?(params[:query].downcase) }

      if @players.blank?
        flash[:error] = "No players matched your search."
      end
    end

    render 'flex_index'
  end

  def create
    params.require(:player).permit!
    player = Player.fake_show(params[:player])
    player.status = "bench"
    player.lineup = @lineup
    @button = "#button-#{player.ff_id}".html_safe
    render "added" if player.save
  end

  def flex_create
    params.permit!
    player = Player.fake_show(JSON.parse(params[:player]))
    if Lineup.find(params[:lineup_id]).players.where(ff_id: player.ff_id).first
      flash[:error] = "Player already exists in this lineup."
    else
      player.status = "bench"
      player.lineup_id = params[:lineup_id]
      if player.save
        flash[:notice] = "#{player.full_name} added to #{Lineup.find(params[:lineup_id]).name}."
      else
        flash[:error] = "Something went wrong."
      end
    end
    redirect_to "#{all_players_path(pos: @pos)}##{player.ff_id}"
  end

  def show
    @player = Statistic.everything.find { |pl| pl['ff_id'] == params[:id] }
    redirect_to home_path unless @player
  end

  def destroy
    player = Player.find(params[:id])
    @article = "#edit-#{player.ff_id}".html_safe
    player.delete
    render "players/delete"
  end

  private
  def find_lineup
    @lineup = Lineup.find_by(token: params[:lineup_id])
  end

  def validate_pos
    params[:pos] = nil unless ['QB', 'RB', 'WR', 'TE', 'K', 'DEF'].include?(params[:pos])
    @pos = params[:pos]
  end
end
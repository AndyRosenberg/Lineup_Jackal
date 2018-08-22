class PlayersController < ApplicationController
  before_action :require_user, except: [:show, :flex_index, :search]
  before_action :find_lineup, except: [:show, :flex_index, :search]

  def index
    everything ||= Statistic.everything.sort {|a, b| b['projected'].to_i - a['projected'].to_i}.first(500)
    @all_players ||= @lineup.filter_players(everything)
    @type = @lineup.league_type
  end

  def flex_index
    @players ||= Statistic.everything.sort {|a, b| b['projected'].to_i - a['projected'].to_i}.first(300)
  end

  def search
    if params[:query].blank?
      @players = []
    else
      @players ||= Statistic.everything.select { |pl| pl['full_name'].downcase.include?(params[:query].downcase) }

      if !@players.blank?
        @players = @players.sort {|a, b| b['projected'].to_i - a['projected'].to_i}
      end
    end

    render 'flex_index'
  end

  def create
    params.require(:player).permit!
    player = Player.fake_show(params[:player])
    player.status = "bench"
    player.lineup_id = params[:lineup_id]
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
    redirect_to "#{all_players_path}##{player.ff_id}"
  end

  def show
    @player = Statistic.everything.find { |pl| pl['ff_id'] == params[:id] }
    redirect_to home_path unless @player
    standard = Statistic.standard.find { |pl| pl['ff_id'] == params[:id] }
    ppr = Statistic.ppr.find { |pl| pl['ff_id'] == params[:id] }
    @player['standard_yrs'] = standard['yrs']
    @player['standard_wks'] = standard['wks']
    @player['ppr_yrs'] = ppr['yrs']
    @player['ppr_wks'] = ppr['wks']
  end

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
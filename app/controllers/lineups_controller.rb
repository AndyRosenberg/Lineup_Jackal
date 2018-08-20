class LineupsController < ApplicationController
  before_action :require_user
  before_action :find_lineup, only: [:show, :compare, :roster, :edit, :update, :destroy]

  def index
    @lineups = current_user.lineups
  end

  def create
    pre = params[:lineup]
    pre[:players] = params[:lineup][:players].select{|ply| ply[:full_name]}
    params.require(:lineup).permit!

    begin
      ActiveRecord::Base.transaction do
        league = Lineup.new({name: pre[:name], league_type: pre[:league_type], user_id: current_user.id})
        league.save!

        pre[:players].each do |item|
          item[:lineup_id] = league.id
          item[:position] = Statistic.find_player(item[:ff_id])['position']
          player = Player.new(item)
          player.save!
          league.players << player
        end

        flash[:notice] = "Lineup created. Last Step - Pick Your Starters!"
        redirect_to roster_lineup_path(league)
      end
    rescue ActiveRecord::RecordInvalid
      flash[:error] = "Invalid Entry"
      redirect_to new_lineup_path
    end
  end

  def new; end

  def show
    @type = @lineup.league_type

    @starters = @lineup.select_players(Statistic.everything, 'starter')
    starters_stats = @lineup.select_players(Statistic.send(@type.to_sym), 'starter')
    merge!(@starters, starters_stats)

    @bench = @lineup.select_players(Statistic.everything, 'bench')
    bench_stats = @lineup.select_players(Statistic.send(@type.to_sym), 'bench')
    merge!(@bench, bench_stats)

    @flex = @lineup.select_players(Statistic.everything, 'flex')
    flex_stats = @lineup.select_players(Statistic.send(@type.to_sym), 'flex')
    merge!(@flex, flex_stats)
  end

  def edit
    @player_info = @lineup.select_players(Statistic.everything)
  end

  def update
    params.require(:plyr).permit!

    begin
      ActiveRecord::Base.transaction do
        params[:plyr].each do |k, v|
        Player.find(k.to_i).update!(status: v[:status])
        end
        flash[:notice] = "Edits Posted!"
      end
    rescue ActiveRecord::RecordInvalid
      flash[:error] = "Something went wrong"
    end

    redirect_to edit_lineup_path(@lineup)
  end

  def destroy; end

  def compare
    @starters = @lineup.starters.map  {|st| [st, st.projected, st.weekly] }
    @total = @lineup.starters.map { |st| st.weekly.to_i }.reduce(&:+)
  end

  def add_comparison
    params.permit!
    @list = ''
    @total2 = 0
    @players = params[:lineup][:players].select{|ply| ply[:full_name]}
    @players = @players.each do |plyr| 
      player = Player.new(plyr.to_h)
      player.lineup_id = params[:id]
      player.position =  Statistic.find_player(player.ff_id)['position']
      @list += "<dt class='h6'>#{player.full_name}"
      @list += "<span class='px-1'>&nbsp;</span>#{player.position} - #{player.team}</dt>"
      @list += "<dd class='d-inline-block px-1'><b>#{player.weekly} points</b> (this week)</dd>"
      @list += "<dd class='d-inline-block px-1'>#{player.projected} points (season)</dd><hr />"
      @total2 += player.weekly.to_i
    end

    @list = @list.html_safe
    @total2 = "<h4 class='text-center'>#{@total2} points this week</h4>".html_safe
  end

  def drop_comparison
  end

  def roster
    @players = @lineup.players
  end

  def set_roster
    params.permit!
    roster = params.to_h
    begin
      ActiveRecord::Base.transaction do
        roster[:statuses].each do |k, v|
          player = Player.find(v[:id])
          player.status = v[:stat]
          player.save!
        end
        flash[:notice] = "Success"
        redirect_to lineups_path
      end
    rescue ActiveRecord::RecordInvalid
      flash[:error] = "Invalid Entry"
      redirect_to roster_lineup_path
    end
  end

  private
  def find_lineup
    @lineup = Lineup.find(params[:id])
  end
  
  def merge!(lineup1, lineup2)
    lineup1.each do |l1|
      match = lineup2.find {|l2| l1['ff_id'] == l2['ff_id'] }
      if match
        l1['yrs'] = match['yrs']
        l1['wks'] = match['wks']
      end
    end
  end
end

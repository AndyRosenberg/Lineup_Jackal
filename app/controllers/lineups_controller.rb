class LineupsController < ApplicationController
  before_action :require_user, except: [:matchup, :add_matchup]
  before_action :load_draft, only: [:matchup, :compare, :new]
  before_action :find_lineup, only: [:show, :compare, :roster, :edit, :update, :destroy, :add_comparison]
  before_action :access_denied?, only: [:show, :compare, :roster, :edit, :update, :destroy, :add_comparison]
  before_action :outdated?, only: [:show, :compare, :roster, :edit, :update, :destroy, :add_comparison]

  def index
    @lineups = current_user.lineups
    fresh_when(@lineups)
  end

  def create
    pre = params[:lineup]
    pre[:players] = params[:lineup][:players].select{|ply| ply[:full_name]}
    params.require(:lineup).permit!

    begin
      ActiveRecord::Base.transaction do
        league = Lineup.new({name: pre[:name], league_type: (pre[:league_type] || "standard"), user_id: current_user.id})
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
    fresh_when(@lineup)
    @type = @lineup.league_type
    everything = Statistic.everything("weekly_#{@type}")

    @starters = @lineup.select_players(everything, 'starter')

    @bench = @lineup.select_players(everything, 'bench')

    @flex = @lineup.select_players(everything, 'flex')
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

  def destroy
    flash[:notice] = "Lineup '#{@lineup.name}' deleted."
    @lineup.delete
    redirect_to lineups_path
  end

  def compare
    @type = @lineup.league_type
    @starters = @lineup.select_players(Statistic.everything("weekly_#{@type}"), 'starter')
    @total = @lineup.starters.map { |st| st.weekly.to_i }.reduce(&:+) || 0
  end

  def add_comparison
    params.permit!
    type = "weekly_#{@lineup.league_type}"
    @list = ''
    @total2 = 0
    @players = params[:lineup][:players].select{|ply| ply[:full_name]}
    @players = @players.each do |plyr| 
      player = Statistic.everything.find {|pl2| pl2['ff_id'] == plyr['ff_id']}
      @list += "<div class='one-opp'><a class='del-comp' data-week=#{player[type]}>&times;</a>"
      @list += "<dt class='h6'>#{player['full_name']}"
      @list += "<span class='px-1'>&nbsp;</span>#{player['position']} - #{player['team']} v. #{player['schedule']}</dt>"
      @list += "<dd class='d-inline-block px-1'><b>#{player[type]} points</b></dd><br />"
      @list += "<dd'>Injuries: #{player['injuries']}</dd><hr /></div>"
      @total2 += player[type].to_i
    end

    @list = @list.html_safe
    @total2 = "<h4 class='text-center' id='opp-total' data-total=#{@total2}>#{@total2} points this week</h4>".html_safe
  end

  def roster
    @players = @lineup.players
    if @players.any? { |pl| !pl.status.nil? }
      flash[:error] = "Roster already set. Please click 'edit' on your lineup to change status."
      redirect_to lineups_path
    end

    @pics = @lineup.select_players(Statistic.everything)
  end

  def set_roster
    params.permit!
    roster = params.to_h
    begin
      ActiveRecord::Base.transaction do
        roster[:statuses].each do |k, v|
          player = Player.find(v[:id])
          player.status = v[:stat] || "bench"
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

  def matchup
  end

  def add_matchup
    params.permit!
    @team = params[:team]
    @list = ''
    @total_std, @total_ppr = 0, 0
    @players = params[:lineup][:players].select{|ply| ply[:full_name]}
    @players = @players.each do |plyr| 
      player = Statistic.everything.find {|pl2| pl2['ff_id'] == plyr['ff_id']}
      @list += "<dt class='h6'>#{player['full_name']}"
      @list += "<span class='px-1'>&nbsp;</span>#{player['position']} - #{player['team']} v. #{player['schedule']}</dt>"
      @list += "<dd class='d-inline-block px-1'><b>#{player['weekly_standard']} points</b> (standard)</dd><br />"
      @list += "<dd class='d-inline-block px-1'><b>#{player['weekly_ppr']} points</b> (ppr)</dd><br />"
      @list += "<dd>Injuries: #{player['injuries']}</dd><hr /></div>"
      @total_std += player['weekly_standard'].to_i
      @total_ppr += player['weekly_ppr'].to_i
    end

    @list = @list.html_safe
    @total_std = "<h4 class='text-center'>Standard: #{@total_std} points</h4>".html_safe
    @total_ppr = "<h4 class='text-center'>PPR: #{@total_ppr} points</h4>".html_safe
  end

  private
  def load_draft
    @draft = Statistic.draft
  end

  def find_lineup
    if Lineup.exists?(token: params[:id])
      @lineup = Lineup.find_by(token: params[:id])
    else
      flash[:error] = "Lineup doesn't exist."
      redirect_to home_path 
    end
  end

  def access_denied?
    unless Lineup.find_by(token: params[:id]).user == current_user
      flash[:error] = "Access Denied"
      redirect_to home_path 
    end
  end

  def outdated?
    unless Lineup.find_by(token: params[:id]).up_to_date?
      flash[:error] = "Cannot access old lineups."
      redirect_to lineups_path
    end
  end
end

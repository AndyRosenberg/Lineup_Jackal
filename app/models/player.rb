class Player < ActiveRecord::Base
  belongs_to :lineup
  validates :ff_id, uniqueness: { scope: :lineup, message: "Only one per lineup" }
  default_scope { order(id: :asc) }
  delegate :league_type, to: :lineup

  def self.fake(hsh, pname = 'display_name', ppos = 'position', pid = 'player_id')
    Player.new(full_name: hsh[pname], position: hsh[ppos], ff_id: hsh[pid])
  end

  def self.fake_show(hsh)
    fake(hsh, 'full_name', 'position', 'ff_id')
  end

  def schedule(pteam = nil)
    pteam ||= self.team
    my_sched = Statistic.schedules.select do |game|
      game['game_week'] == CURRENT_WEEK.to_s &&
      (game['home_team'] == pteam || game['away_team'] == pteam)
    end

    if my_sched.empty? 
      'BYE' 
    else
      game = my_sched.first
      game['home_team'] == pteam ? game['away_team'] : "@#{game['home_team']}"
    end
  end

  def last_5
    Statistic.last_5.map do |k, v|
      {k => v.find {|pl| pl['ff_id'] == ff_id} }
    end
  end

  def l5
    last_5.flat_map do |yr|
      yr.map do |k, v| 
        if v
          "#{k} totals: | #{v.map {|k2, v2| "#{k2}: #{v2}" unless k2.match(/(ff|play|pos|tea)/)}.compact.join(" | ")}"
        else
          "#{k} totals: Not Applicable"
        end
      end
    end
  end

  def this_year_total
    Statistic.this_year.map do |k, v|
      {k => v.find {|pl| pl['ff_id'] == ff_id} }
    end
  end

  def weeks_this_year
    Statistic.weeks_this_year.map do |k, v|
      {k => v.find {|pl| pl['ff_id'] == ff_id} }
    end
  end

  def wty
    weeks_this_year.flat_map do |yr|
      yr.map do |k, v| 
        if v
          "#{k}: | #{v.map {|k2, v2| "#{k2}: #{v2}" unless k2.match(/(ff|play|pos|tea)/)}.compact.join(" | ")}"
        else
          "#{k}: Not Applicable"
        end
      end
    end
  end

  def projected
    pj = Statistic.draft[position].find {|plyr| plyr['player_id'] == ff_id }
    pj ? pj['fantasyPoints'] : "0"
  end

  def weekly(type = nil)
    type = (type || league_type)
    pj = Statistic.weekly[position].find {|plyr| plyr['player_id'] == ff_id }
    pj ? pj[type] : "0"
  end

  def team
    tm = Statistic.active_players.find {|plyr| plyr['player_id'] == ff_id }
    tm ? tm['team'] : "N/A"
  end

  def image
    "https://www.fantasyfootballnerd.com/images/players_large/#{ff_id}.png"
  end

  def more_links
    return nil if position == "DEF"
    split = full_name.downcase.gsub(/[^a-z -]/, '').split(' ')[0..1]
    minussed = split.join('-')
    { "for4": "https://www.4for4.com/fantasy-football/player/#{minussed}",
       "ffnerd": "https://www.fantasyfootballnerd.com/player/#{ff_id}/#{minussed}"
    }
  end

  def injuries
    inj = Statistic.injuries.find { |pl| pl['player_id'] == ff_id }
    inj ? "#{inj['game_status'].split(' ').first} - #{inj['injury']}" : "None"
  end

end
class Player < ActiveRecord::Base
  belongs_to :lineup
  validates :ff_id, uniqueness: { scope: :lineup, message: "Only one per lineup" }
  default_scope { order(id: :asc) }
  delegate :league_type, to: :lineup

  def last_5
    map_stat_model(:last_5)
  end

  def weeks_this_year
    map_stat_model(:weeks_this_year)
  end

  def l5
    map_stat(:last_5, "Season")
  end

  def wty
    map_stat(:weeks_this_year)
  end

  def projected
    pj = find_stat_model_player(:draft)
    pj ? pj['fantasyPoints'] : "0"
  end

  def weekly(type = nil)
    type ||= league_type
    pj = find_stat_model_player(:weekly)
    pj ? pj[type] : "0"
  end

  def team
    tm = find_stat_model_player(:active_players)
    tm ? tm['team'] : "N/A"
  end

  def injuries
    inj = find_stat_model_player(:injuries)
    if inj 
      status = inj['game_status'][0, 3] == "Did" ? "DNP" : inj['game_status'].split(' ').first
      "#{status} - #{inj['injury']}" 
    else
      "None"
    end
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

  def self.fake(hsh, pname = 'display_name', ppos = 'position', pid = 'player_id')
    Player.new(full_name: hsh[pname], position: hsh[ppos], ff_id: hsh[pid])
  end

  def self.fake_show(hsh)
    fake(hsh, 'full_name', 'position', 'ff_id')
  end

  private
  def format_stat(arr)
    arr.map { |k2, v2| "#{k2}: #{v2.gsub('*', '')}" unless k2.match(/(ff|play|pos|tea)/) }.compact.join(" | ")
  end

  def map_stat(stat, text = nil)
    self.send(stat).flat_map do |st|
      st.map do |k, v| 
        if v
          "#{text}: #{k} | #{ format_stat(v) }"
        else
          "#{text}: #{k} | Not Applicable"
        end
      end
    end
  end

  def map_stat_model(table)
    Statistic.send(table).map do |k, v|
      { k => v.find { |pl| pl['ff_id'] == ff_id } }
    end
  end

  def find_stat_model_player(table)
    result = Statistic.send(table)
    result = result[position] if (table == :draft || table == :weekly)
    result.find {|plyr| plyr['player_id'] == ff_id }
  end

end
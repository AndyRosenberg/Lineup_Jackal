class Statistic < ActiveRecord::Base
  def self.players
    access('players')
  end

  def self.active_players(pos = nil)
    pos ? players.select { |pl| pl["position"] == pos && pl["active"] == "1" } : players.select { |pl| pl["active"] == "1" }
  end

  def self.fakes(pos = nil)
    active_players(pos).map { |pl| Player.fake(pl) }
  end

  def self.create_everything
    fakes.map do |fake|
      hsh = JSON.parse(fake.to_json)
      hsh["team"] = fake.team
      hsh["projected"] = fake.projected
      hsh["weekly_standard"] = fake.weekly('standard')
      hsh["weekly_ppr"] = fake.weekly('ppr')
      hsh["image"] = fake.image
      hsh
    end
  end

  def self.everything_scored
    scored = everything.sort {|a, b| b['projected'].to_i - a['projected'].to_i}.select {|pl| pl['projected'].to_i > 0 }
    scored = scored.map { |pl| Player.fake_show(pl) }
  end

  def self.create_stats(type)
    everything_scored.map do |fake|
      hsh = JSON.parse(fake.to_json)
      hsh["wks"] = fake.weeks_format(type)
      hsh["yrs"] = fake.last_5_format(type)
      hsh
    end
  end

  def self.update_weeks(type)
    self.send(type.to_sym).map do |pl|
      fake = Player.fake_show(pl)
      pl["wks"] = fake.weeks_format(type)
      pl
    end
  end

  def self.standard
    access("standard")
  end

  def self.ppr
    access("ppr")
  end

  def self.everything
    access('everything')
  end

  def self.draft
    access('draft')
  end

  def self.weekly
    access('weekly')
  end

  def self.images
    access('images')
  end

  def self.weeks_this_year
    access('prev_weeks')
  end

  def self.last_5
    access("last_5")
  end

  def self.find_player(ffid)
    access('players').select { |plyr| plyr["player_id"] == ffid }.first
  end

  def self.find_by_name(name, team = nil)
    result = []
    if team
      result = players.select {|plyr| plyr['display_name'].downcase == name.downcase && plyr['team'].downcase == team.downcase }
    else
      result = players.select {|plyr| plyr['display_name'].downcase == name.downcase }
    end
    return result if result.empty? || result.size > 1
    result.first
  end

  def self.projected_annual(ffid)
    Statistic.draft.flat_map { |k, v| v }.select { |pl| pl['player_id'] == ffid }.first['fantasy_points'].to_i
  end

  def self.prev_n_years(num)
    result = {}
    yr_code = ''
    current = DateTime.now
    last_2 = current.year.to_s[-2, 2].to_i

    if current.month < 3
      yr_code = ((last_2 - 1) * 32) + 13
    else
      yr_code = (last_2 * 32) + 13
    end

    ((current.year - num)...current.year).to_a.reverse.each do |year|
      2.times do |n|
        score = n == 0 ? 10 : 2
        url = "https://www.fantasysharks.com/apps/bert/stats/points.php?League=-1&Position=99&scoring=#{score}&Segment=#{yr_code}"
        if n == 0
          result["#{year}_standard"] = gen_prev(url) 
        else 
          result["#{year}_ppr"] = gen_prev(url)
        end
      end

      yr_code -= 32
    end
    result
  end

  def self.this_year(week = nil)
    result = {}
    yr_code = ''
    current = DateTime.now
    last_2 = current.year.to_s[-2, 2].to_i

    if current.month < 3
      yr_code = (last_2 * 32) + 13
    else
      yr_code = ((last_2 + 1) * 32) + 13
    end

    if week
      yr_code += (6 + week)
    end

    2.times do |n|
      score = n == 0 ? 10 : 2
      url = "https://www.fantasysharks.com/apps/bert/stats/points.php?League=-1&Position=99&scoring=#{score}&Segment=#{yr_code}"
      if n == 0
        result["#{current.year}_standard"] = gen_prev(url) 
      else 
        result["#{current.year}_ppr"] = gen_prev(url)
      end
    end
    result
  end

  def self.prev_weeks
    final = {}
    current_week = CURRENT_WEEK.to_i
    current_week.times do |n|
      num = n + 1
      wk = Statistic.this_year(num)
      wk.each {|k, v| final["#{num}_#{k}"] = v }
    end

    final
  end

  def self.find_image(player_name)
    image_link = nil
    split_name = player_name.split(' ')
    joined = player_name.split(' ').join('').downcase

    nfl_search = HTTParty.get("http://www.nfl.com/players/search?category=name&filter=#{split_name[0]}+#{split_name[1]}&playerType=current")

    nfl_search = Nokogiri::HTML(nfl_search).at('#result')
    return nil if !nfl_search

    linked_profile = nfl_search.search('td a').find {|link| link.attr('href').include?(joined) }
    return nil if !linked_profile

    linked_profile = linked_profile.attr('href')

    nfl_player = HTTParty.get("http://www.nfl.com/#{linked_profile}")
    nfl_player = Nokogiri::HTML(nfl_player)

    image_link = nfl_player.at('#player-bio').search('img').first.attr('src')
  end

  private
  def self.access(str)
    name = find_by(name: str)
    name ? JSON.parse(name.json) : nil
  end

  def self.gen_prev(url)
    scrape = HTTParty.get(url)

    scrape = Nokogiri::HTML(scrape)

    stats = scrape.at('#toolData').search('tr').map{|tr| tr.search('td').map(&:text)}

    names = ['rank', 'player', 'team', 'position', 'pass_yds', 'pass_tds', 'rush_yds', 'rush_tds', 'receptions', 'rec_yds', 'rec_tds', 'fgm', 'pts_against', 'tackle', 'pts_total']

    stats.map do |stat|
      unless stat.blank?
        result = {}
        stat.each_with_index do |st, idx|
          result[names[idx]] = st
        end
      end
      result
    end.compact
  end

end

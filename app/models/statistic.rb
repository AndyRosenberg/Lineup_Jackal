class Statistic < ActiveRecord::Base
  def self.schedules
    access('schedules')
  end

  def self.players
    access('players')
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

  def self.injuries
    access('injuries')
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
      hsh["schedule"] = fake.schedule(hsh["team"])
      hsh["injuries"] = fake.injuries
      hsh["projected"] = fake.projected
      hsh["weekly_standard"] = fake.weekly('standard')
      hsh["weekly_ppr"] = fake.weekly('ppr')
      hsh["l5"] = fake.l5
      hsh["wty"] = fake.wty
      hsh["image"] = fake.image
      hsh["links"] = fake.more_links
      hsh
    end
  end

  def self.find_by_name(name)
    result = players.find {|plyr| plyr['display_name'].downcase.gsub(/[,.']/, '').include?(name.downcase.gsub(/[,.']/, '')) }

    return result['player_id'] if result
    nil
  end

  def self.projected_annual(ffid)
    Statistic.draft.flat_map { |k, v| v }.select { |pl| pl['player_id'] == ffid }.first['fantasy_points'].to_i
  end

  def self.prev_n_years(num)
    result = {}
    current = DateTime.now
    yr_code = determine_year_code(current, 'past')

    ((current.year - num)...current.year).to_a.reverse.each do |year|
      fantasy_sharks(result, yr_code, year)
      yr_code -= 32
    end

    result
  end

  def self.this_year(week = nil)
    result = {}
    current = DateTime.now
    yr_code = determine_year_code(current, 'present')

    if week
      yr_code += (6 + week)
    end

    fantasy_sharks(result, yr_code, current.year)

    result
  end

  def self.prev_weeks
    final = {}
    current_week = CURRENT_WEEK.to_i
    current_week.times do |n|
      num = n + 1
      wk = Statistic.this_year(num)
      wk.each {|k, v| final["Week #{num}"] = v }
    end

    final
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

    names = ['rank', 'player', 'team', 'position', 'pass_yds', 'pass_tds', 'rush_yds', 'rush_tds', 'receptions', 'rec_yds', 'rec_tds', 'fgm', 'pts_against', 'tackle', 'total_points']

    stats.map do |stat|
      unless stat.blank?
        result = {}
        stat.each_with_index do |st, idx|
          if idx == 1
            st = st.gsub(/[,.']/, '').split(' ')
            st = st[1..-1].concat(st[0..0])
            st = st.first.downcase.match(/(jr|sr|iii)/) ? st[1..-1].join(' ') : st.join(' ')
          end
          result[names[idx]] = st if st != "0"
        end

        ffid = find_by_name(result['player'])
        result['ff_id'] = ffid if ffid
      end

      result
    end.compact
  end

  def self.fantasy_sharks(result, yr_code, year)
    url = "https://www.fantasysharks.com/apps/bert/stats/points.php?League=-1&Position=99&scoring=10&Segment=#{yr_code}"
    result["#{year}"] = gen_prev(url)
  end

  def self.determine_year_code(current, tense)
    last_2 = current.year.to_s[-2, 2].to_i

    if tense == 'present'
      if current.month < 3
        (last_2 * 32) + 13
      else
        ((last_2 + 1) * 32) + 13
      end
    else
      if current.month < 3
        ((last_2 - 1) * 32) + 13
      else
        (last_2 * 32) + 13
      end
    end
  end

end

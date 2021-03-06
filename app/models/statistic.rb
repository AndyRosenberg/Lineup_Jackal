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

  def self.everything(filter = nil)
    filter ||= 'projected'
    access('everything').sort_by {|pl| pl[filter].to_f }.reverse
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

  def self.ev_pos(pos = nil)
    return everything unless pos
    everything.select { |plyr| plyr["position"] == pos }
  end

  def self.find_player(ffid)
    access('players').select { |plyr| plyr["player_id"] == ffid }.first
  end

  def self.find_by_name(name)
    result = everything.find {|plyr| plyr['full_name'].downcase.gsub(/[,.']/, '').include?(name.downcase.gsub(/[,.']/, '')) }

    return result['ff_id'] if result
    nil
  end

  def self.active_players(pos = nil)
    pos ? players.select { |pl| pl["position"] == pos && pl["active"] == "1" } : players.select { |pl| pl["active"] == "1" }
  end

  def self.fakes(pos = nil)
    active_players(pos).map { |pl| Player.fake(pl) }
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
    (1...CURRENT_WEEK).each do |n|
      wk = Statistic.this_year(n)
      wk.each {|k, v| final["Week #{n}"] = v }
    end

    final
  end

  private
  def self.access(str)
    name = find_by(name: str)
    name ? JSON.parse(name.json) : nil
  end

  def self.gen_prev(url)
    stats = Rails.env.production? ? prod_scrape(url) : dev_scrape(url)

    format_scrape(stats).compact
  end

  def self.dev_scrape(url)
    scrape = Nokogiri::HTML(open(url))
    scrape.at('#toolData').search('tr').map{|tr| tr.search('td').map(&:text)}
  end

  def self.prod_scrape(url)
    scrape = Scrapetastic::APIController.new
    results = scrape.lookup(url, '#toolData tr', '', '')
    results.values.map do |res|
      res.gsub!(', ', '~~')
      prod_doubles!(res)
      res = res.split(' ')
      res[1].gsub!('~~', ', ')
      res[1].gsub!('``', ' ')
      res
    end
  end

  def self.prod_doubles!(str)
    if scraped_2w_defense?(str)
      double = { 
                       'Kansas City': 'Kansas``City', 'Green Bay': 'Green``Bay', 
                       'Tampa Bay': 'Tampa``Bay', 'Los Angeles': 'Los``Angeles', 
                       'New Orleans': 'New``Orleans', 'New York': 'New``York',
                       'New England': 'New``England', 'San Francisco': 'San``Francisco' 
                       }
      correct_double = double.keys.map(&:to_s).find { |dbl| str.include?(dbl) }
      str.gsub!(correct_double, double[correct_double.to_sym])
    else
      str
    end
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

  def self.format_scrape(stats)
    stats.map do |stat|
      unless stat.blank?
        result = {}
        stat.each_with_index do |st, idx|
          if idx == 1
            st = scrape_name(st)
          end

          determine_pair(st, idx, stat, result)
        end

        ffid = find_by_name(result['player'])
        result['ff_id'] = ffid if ffid
      end
      result
    end
  end

  def self.scraped_2w_defense?(st)
    return false if st.size < 3
    doubles = ['Green Bay', 'Tampa Bay', 'Los Angeles', 'New Orleans', 'New York', 'New England', 'San Francisco', 'Kansas City']
    doubles.any? { |dbl| st.include?(dbl) }
  end

  def self.scraped_surname?(st)
    st.first.downcase.match(/(jr|sr|iii)/)
  end

  def self.scrape_name(st)
    st = st.gsub(/[,.']/, '').split(' ')
    if scraped_2w_defense?(st)
      st[-1, 1].concat(st[0..-2]).join(' ')
    else
      st = st[1..-1].concat(st[0..0])
      scraped_surname?(st) ? st[1..-1].join(' ') : st.join(' ')
    end
  end

  def self.determine_pair(st, idx, stat, result)
    names1 = ['Rank', 'player', 'team', 'position', 'Passing Yds', 'Passing TDs', 'Rushing Yds', 'Rushing TDs', 'Receptions', 'Receiving Yds', 'Receiving TDs', 'Field Goals Made', 'Points Against', 'Tackles', 'Fantasy Points']
    names2 = ['Rank', 'player', 'team', 'Opp', 'position', 'Passing Yds', 'Passing TDs', 'Rushing Yds', 'Rushing TDs', 'Receptions', 'Receiving Yds', 'Receiving TDs', 'Field Goals Made', 'Points Against', 'Tackles', 'Fantasy Points']

    if stat.size == 16
      result[names2[idx]] = st if (st != "0" || idx == stat.size - 1)
    else
      result[names1[idx]] = st if (st != "0" || idx == stat.size - 1)
    end
  end

end

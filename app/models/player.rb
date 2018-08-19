class Player < ActiveRecord::Base
  belongs_to :lineup
  validates :ff_id, uniqueness: { scope: :lineup, message: "Only one per lineup" }
  delegate :league_type, to: :lineup

  def self.fake(hsh, pname = 'display_name', ppos = 'position', pid = 'player_id')
    Player.new(full_name: hsh[pname], position: hsh[ppos], ff_id: hsh[pid])
  end

  def self.fake_show(hsh)
    fake(hsh, 'full_name', 'position', 'ff_id')
  end

  def self.last_5(name, type)
    Statistic.last_5.map do |k, v|
      {k => v.select {|plyr| plyr['player'].downcase == name.split(' ').reverse.join(', ').downcase }.first}
    end.select {|hsh| hsh.keys[0].include?(type)}
  end

  def last_5(no_type = nil)
    type = no_type || league_type
    Statistic.last_5.map do |k, v|
      if position == 'DEF'
        test_name = full_name.split(' ')
        test_name = [(test_name[-1] + ',')] + test_name[0..-2]
        test_name = test_name.join(' ')

        {  k => v.select { |plyr| plyr['player'].downcase == test_name.downcase }.first }
      else
        {k => v.select {|plyr| plyr['player'].downcase == full_name.split(' ').reverse.join(', ').downcase }.first}
      end
    end.select {|hsh| hsh.keys[0].include?(type)}
  end

  def last_5_format(no_type = nil)
    type = no_type || league_type
    result = []
    flattened = []
    if !last_5(type).first.values[0]
      split = full_name.split(' ')
      joined = split[0..1].join(' ')
      short = Player.last_5(joined, type)
      if short.first.values[0]
        flattened = short.flat_map(&:to_a)
      else
        return "N/A"
      end
    else
      flattened = last_5(type).flat_map(&:to_a)
    end

    flattened.each do |flat|
      yr = flat[0].split('_')[0]
      stats = flat[1] ? flat[1].map{|k, v| "#{k}: #{v}"}[4..-1].join(' | ') : "N/A"
      result << "#{yr}~#{stats}".split('~')
    end
    result
  end

  def this_year_total
    type = league_type
    Statistic.this_year.map do |k, v|
      if position == 'DEF'
        test_name = full_name.split(' ')
        test_name = [(test_name[-1] + ',')] + test_name[0..-2]
        test_name = test_name.join(' ')

        {  k => v.select { |plyr| plyr['player'].downcase == test_name.downcase }.first }
      else
        {k => v.select {|plyr| plyr['player'].downcase == full_name.split(' ').reverse.join(', ').downcase }.first}
      end
    end.select {|hsh| hsh.keys[0].include?(type)}
  end

  def weeks_this_year(no_type = nil)
    type = no_type || league_type
    Statistic.this_year.map do |k, v|
      if position == 'DEF'
        test_name = full_name.split(' ')
        test_name = [(test_name[-1] + ',')] + test_name[0..-2]
        test_name = test_name.join(' ')

        {  k => v.select { |plyr| plyr['player'].downcase == test_name.downcase }.first }
      else
        {k => v.select {|plyr| plyr['player'].downcase == full_name.split(' ').reverse.join(', ').downcase }.first}
      end
    end.select {|hsh| hsh.keys[0].include?(type)}
  end

  # insert weeks stats into db

  def weeks_format(no_type = nil)
    type = no_type || league_type
    result = []
    flattened = []
    if !weeks_this_year(type).first.values[0]
      split = full_name.split(' ')
      joined = split[0..1].join(' ')
      short = self.clone
      short.full_name = joined
      short = short.weeks_this_year(type)
      if short.first.values[0]
        flattened = short.flat_map(&:to_a)
      else
        return "N/A"
      end
    else
      flattened = weeks_this_year(type).flat_map(&:to_a)
    end

    flattened.each do |flat|
      yr = flat[0].split('_')[0]
      stats = flat[1] ? flat[1].map{|k, v| "#{k}: #{v}"}[4..-1].join(' | ') : "N/A"
      result << "Week #{yr[0]}~#{stats}".split('~')
    end
    result
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
    john_doe = "http://static.nfl.com/static/content/public/static/img/fantasy/transparent/200x200/BEV146616.png"
    img = Statistic.images.find {|img| img.include?(ff_id)}
    if img
      img[ff_id]
    elsif full_name.split(' ').length > 2
      Statistic.find_image(full_name.split(' ')[0..1].join(' ')) || john_doe
    else 
      john_doe
    end
  end

  def self.image(ffid)
    img = Statistic.images.find {|img| img.include?(ffid)}
    img ? img[ffid] : "https://www.bsn.eu/wp-content/uploads/2016/12/user-icon-image-placeholder-300-grey.jpg"
  end

end
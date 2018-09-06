class Lineup < ActiveRecord::Base
  belongs_to :user
  has_many :players, dependent: :delete_all
  validates_presence_of :name
  before_create :generate_token

  def bench
    players.where(status: "bench")
  end

  def starters
    players.where(status: "starter")
  end

  def flex
    players.where(status: "flex")
  end

  def injury_reserve
    players.where(status: "ir")
  end

  def season
    cr = created_at
    yr = cr.year
    cr.month < 3 ? yr - 1 : yr
  end

  def current_season
    curr = DateTime.now
    yr = curr.year
    curr.month > 2 ? yr : yr - 1
  end

  def up_to_date?
    season == current_season
  end

  def filter_players(all)
    all.select do |plyr|
      players.none? do |m_p|
        m_p.ff_id == plyr['ff_id']
      end
    end
  end

  def select_players(all, status = nil)
    all.select do |plyr|
      players.any? do |m_p|
        status ? m_p.ff_id == plyr['ff_id'] && m_p.status == status : m_p.ff_id == plyr['ff_id']
      end
    end
  end

  def generate_token
    self.token = SecureRandom.urlsafe_base64(15)
  end

  def self.create_tokens!
    all.each do |lineup|
      if !lineup.token
        lineup.generate_token
        lineup.save
      end
    end
  end

  def to_param
    self.token
  end
end
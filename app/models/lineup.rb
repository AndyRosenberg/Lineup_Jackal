class Lineup < ActiveRecord::Base
  belongs_to :user
  has_many :players, dependent: :delete_all
  validates_presence_of :name

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
    created_at.month < 3 ? created_at.year - 1 : created_at.year
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
end
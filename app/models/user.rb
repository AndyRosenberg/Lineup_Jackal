class User < ActiveRecord::Base
  has_many :lineups
  #has_many :players
  has_secure_password validations: false
  validates :password, presence: true, on: :create, length: {minimum: 7}
  validates :email, presence: true
  validates :username, presence: true

  def wishlist
    players
  end
end
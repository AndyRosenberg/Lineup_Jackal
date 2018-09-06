class User < ActiveRecord::Base
  has_many :lineups

  has_secure_password validations: false
  validates :password, presence: true, on: :create, length: {minimum: 7}
  validates :email, presence: true, uniqueness: true
  validates :username, presence: true, uniqueness: true
  before_save :generate_slug

  def generate_slug
    self.slug = "#{self.username.parameterize}#{SecureRandom.urlsafe_base64(6)}"
  end

  def to_param
    self.slug
  end
end
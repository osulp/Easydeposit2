class User < ActiveRecord::Base
  has_many :events, inverse_of: :user
  has_many :author_publications, inverse_of: :user
  has_and_belongs_to_many :publications

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  before_save :set_username

  private
  def set_username
    self.username = self.email
  end
end

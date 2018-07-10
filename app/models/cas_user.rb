class CasUser < ActiveRecord::Base
  has_many :jobs, inverse_of: :cas_user
  has_and_belongs_to_many :publications

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :cas_authenticatable

  def cas_extra_attributes=(extra_attributes)
    extra_attributes.each do |name, value|
      case name.to_sym
      when :fullname
        self.display_name = value
      when :email
        self.email = value
      end
    end
  end
end

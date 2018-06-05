class ApplicationController < ActionController::Base
  include Devise::Controllers::Helpers

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Shoehorn both User and CasUser models into devise as 'current_user', this allows
  # the application to behave in a sane way regardless of which authentication method
  # is used to log the user in.
  devise_group :user, contains: [:user, :cas_user]
  before_action :authenticate_or_redirect_user!

  private
  def authenticate_or_redirect_user!
    if user_signed_in? || %w(sessions cas_sessions registrations passwords).include?(controller_name)
      authenticate_user!
    else
      redirect_to new_user_session_path
    end
  end
end

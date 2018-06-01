class ApplicationController < ActionController::Base
  include Devise::Controllers::Helpers

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Shoehorn both User and CasUser models into devise as 'current_user', this allows
  # the application to behave in a sane way regardless of which authentication method
  # is used to log the user in.
  devise_group :user, contains: [:user, :cas_user]
  before_action :authenticate_user!
end

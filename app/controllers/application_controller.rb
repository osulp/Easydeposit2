class ApplicationController < ActionController::Base
  include Devise::Controllers::Helpers

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Shoehorn both User and CasUser models into devise as 'current_user', this allows
  # the application to behave in a sane way regardless of which authentication method
  # is used to log the user in.
  devise_group :user, contains: [:user, :cas_user]
  before_action :store_location!, if: :storable_location?
  before_action :authenticate_user!, except: [:sessions, :cas_sessions, :registrations, :passwords]

  private

  ##
  # Override Devise method to manually set the key to :user since
  # this application make use of a devise_group containing multiple models
  def stored_location_for(resource)
    session_key = stored_location_key_for(:user)
    return session.delete(session_key) if is_navigational_format?
    session[session_key]
  end

  # Its important that the location is NOT stored if:
  # - The request method is not GET (non idempotent)
  # - The request is handled by a Devise controller such as Devise::SessionsController as that could cause an
  #    infinite redirect loop.
  # - The request is an Ajax request as this can lead to very unexpected behaviour.
  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end

  ##
  # Store the location for redirection after successful authentication
  def store_location!
    store_location_for(:user, request.fullpath)
  end
end

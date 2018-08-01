class HomeController < ApplicationController
  before_action :get_records

  def index
    respond_to do |format|
      format.html { render :index }
      format.json { head :no_content }
    end
  end

  private

  def get_records
    if current_user.admin?
      @events = Event.includes(publication: [:cas_users, :users, :web_of_science_source_record]).all
    else
      @publications = current_user.publications.includes(:events)
    end
  end
end

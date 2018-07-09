class HomeController < ApplicationController
  def index
    if current_user.admin?
      @jobs = Job.includes(:publication).all
      respond_to do |format|
        format.html { render :admin_index }
        format.json { head :no_content }
      end
    end
  end
end

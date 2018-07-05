require 'csv'

class PublicationsController < ApplicationController
  # before_action :check_authorization

  def harvest
    institution = ["Oregon State University", "Oregon State Univ"]
    if InstitutionHarvestJob.perform_later(institution)
      render json: {
          response: "Harvest for institution was successfully created."
      }, status: :accepted
    else
      render json: {
          error: "Harvest for institution failed."
      }, status: :error
    end
  end

  def index
    @wos_records = WebOfScienceSourceRecord.includes(:publication).all
  end
end

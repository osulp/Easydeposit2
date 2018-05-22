# frozen_string_literal: true

class HomeController < ApplicationController
  # before_action :authenticate_user!

  def index
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

  private

end
require 'csv'

class PublicationsController < ApplicationController
  before_action :get_record, only: [:show, :edit, :update, :delete_file]

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

  def show
    redirect_to edit_publication_path(@publication)
  end

  def edit
  end

  def update
    respond_to do |format|
      if @publication.has_unique_publication_files(publication_params[:publication_files]) && @publication.update(publication_params)
        format.html { redirect_to edit_publication_path(@publication), notice: 'Publication was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @publication.errors, status: :unprocessable_entity }
      end
    end
  end

  def delete_file
    respond_to do |format|
      file = @publication.publication_files.find(params[:file_id])
      if file.purge
        format.html { redirect_to edit_publication_path(@publication), notice: "#{file.blob.filename} was deleted." }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @publication.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def get_record
    id = params[:id] || params[:publication_id]
    @wos_record = WebOfScienceSourceRecord.includes(:publication).where(uid: id).first
    @publication = @wos_record.publication
  end

  def publication_params
    params.require(:publication).permit(publication_files: [])
  end
end

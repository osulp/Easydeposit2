require 'csv'

class PublicationsController < ApplicationController
  before_action :get_record, except: [:index, :harvest, :claim]
  before_action :get_record_by_hashed_uid, only: :claim

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
        files = publication_params[:publication_files].map{ |p| p.original_filename }
        job = Job.create(Job::FILE_ADDED.merge({ message: files.join(', ') }))
        current_user.jobs << job
        @publication.jobs << job
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
        job = Job.create(Job::FILE_DELETED.merge({ message: file.blob.filename }))
        current_user.jobs << job
        @publication.jobs << job
        format.html { redirect_to edit_publication_path(@publication), notice: "#{file.blob.filename} was deleted." }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @publication.errors, status: :unprocessable_entity }
      end
    end
  end

  def restart_job
    job = Job.find(params[:job_id])
    current_user.jobs << job
    job.retry
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path, notice: "Restarted Job, please check back for status update.") }
      format.json { head :no_content }
    end
  end

  def claim
    current_user.publications << @publication
    respond_to do |format|
      format.html { redirect_to edit_publication_path(@publication), notice: "You've claimed this publication, please update and publish it." }
      format.json { head :no_content }
    end
  end

  private

  def get_record_by_hashed_uid
    @wos_record = WebOfScienceSourceRecord.includes(:publication).where(hashed_uid: params[:hashed_uid]).first
    @publication = @wos_record.publication
  end

  def get_record
    id = params[:id] || params[:publication_id]
    @wos_record = WebOfScienceSourceRecord.includes(:publication).where(uid: id).first
    @publication = @wos_record.publication
  end

  def publication_params
    params.require(:publication).permit(publication_files: [])
  end
end

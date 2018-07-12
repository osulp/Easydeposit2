require 'csv'

class PublicationsController < ApplicationController
  before_action :get_record, except: [:index, :harvest, :claim]
  before_action :get_record_by_hashed_uid, only: :claim
  before_action :user_is_admin?, only: [:index, :harvest]
  before_action :user_has_access?, except: [:index, :harvest, :claim]
  before_action :record_is_published?, only: [:update, :delete_file, :claim, :publish]

  def harvest
    institution = ["Oregon State University", "Oregon State Univ"]
    InstitutionHarvestJob.perform_later(institution)
    flash[:warn] = "The system is harvesting new publications"
    redirect_to root_path
  end

  def index
    @publications = Publication.includes(:web_of_science_source_record, :jobs).all
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
    job.retry(current_user)
    flash[:warn] = "Reprocessing event, please check back later for an update"
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) }
      format.json { head :no_content }
    end
  end

  def claim
    current_user.publications << @publication
    flash[:warn] = "You've claimed this publication, please update and publish it."
    respond_to do |format|
      format.html { redirect_to edit_publication_path(@publication) }
      format.json { head :no_content }
    end
  end

  def publish
    job = @publication.jobs.where(name: Job::PUBLISH_WORK[:name]).first
    PublishWorkJob.perform_now(publication: @publication, current_user: current_user, previous_job: job)
    flash[:warn] = "Publishing work to repository."
    respond_to do |format|
      format.html { redirect_to edit_publication_path(@publication) }
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

  def user_is_admin?
    redirect_to(root_path, alert: "You are not authorized to access this page.") unless current_user.admin?
  end

  def user_has_access?
    redirect_to(root_path, alert: "You are not authorized to access this page.") unless current_user.admin? || current_user.publications.include?(@publication)
  end

  def record_is_published?
    if @publication.published?
      redirect_to edit_publication_path(@publication), alert: "This publication has already been published, it can only be modified in the repository."
    end
  end
end

# frozen_string_literal: true

##
# Controller to handle actions related to a publication
class PublicationsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:claim]
  before_action :login_claim_link_user, only: [:claim]
  before_action :record, except: %i[index harvest claim]
  before_action :user_is_admin?, only: %i[index harvest]
  before_action :user_has_access?, except: %i[index harvest claim]
  before_action :published?, only: %i[update delete_file claim publish]
  before_action :claim_publication, only: %i[claim edit update]

  def harvest
    institution = ENV['ED2_WOS_SEARCH_TERMS'].split('|')
    InstitutionHarvestJob.perform_later(institution)
    flash[:warn] = 'The system is harvesting new publications'
    redirect_to root_path
  end

  def index
    @publications = Publication.includes(:web_of_science_source_record, :events).all
  end

  def show; end
  def edit; end

  def update
    respond_to do |format|
      if @publication.unique_publication_files?(publication_params[:publication_files]) && @publication.update(publication_params)
        create_event(Event::FILE_ADDED.merge(message: publication_params[:publication_files]
                                                      .map(&:original_filename)
                                                      .join(', ')))
        format.html do
          redirect_to edit_publication_path(@publication),
                      notice: t('publications.update_message')
        end
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json do
          render json: @publication.errors,
                 status: :unprocessable_entity
        end
      end
    end
  end

  def delete_file
    respond_to do |format|
      if @file.purge
        create_event(Event::FILE_DELETED.merge(message: @file.blob.filename))
        format.html do
          redirect_to edit_publication_path(@publication),
                      notice: t('publications.delete_file_message',
                                filename: @file.blob.filename)
        end
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json do
          render json: @publication.errors,
                 status: :unprocessable_entity
        end
      end
    end
  end

  def restart_event
    current_user.events << @event
    @event.retry(current_user)
    flash[:warn] = t('publications.restart_event_message')
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) }
      format.json { head :no_content }
    end
  end

  def claim
    flash[:warn] = t('publications.claim_message')
    respond_to do |format|
      format.html { redirect_to edit_publication_path(@publication) }
      format.json { head :no_content }
    end
  end

  def publish
    event = @publication.events.where(name: Event::PUBLISH_WORK[:name]).first
    PublishWorkJob.perform_later(publication: @publication,
                                 current_user: current_user,
                                 previous_event: event)
    flash[:warn] = 'Publishing work to repository.'
    respond_to do |format|
      format.html { redirect_to publication_path(@publication) }
      format.json { head :no_content }
    end
  end

  private

  def claim_publication
    current_user.publications << @publication unless current_user.publications.include?(@publication)
    @publication.await_attachments! if @publication.may_await_attachments?
  end

  def record_by_hashed_uid
    @wos_record = WebOfScienceSourceRecord.includes(:publication)
                                          .where(hashed_uid: params[:hashed_uid])
                                          .first
    @publication = @wos_record.publication
  end

  ##
  # Use hashed_email (claim_link) to identify the correct publication to be claimed, and
  # Login/associate user to a publication by the hashed email (i.e., claim_link)
  def login_claim_link_user
    @author_publication = AuthorPublication.includes(:publication)
                                           .where(claim_link: params[:claim_link])
                                           .first
    @publication = @author_publication.publication
    @user = @author_publication.user
    sign_in(@user)
  end

  def record
    id = params[:id] || params[:publication_id]
    @wos_record = WebOfScienceSourceRecord.includes(:publication)
                                          .where(uid: id)
                                          .first
    @publication = @wos_record.publication
    @event = Event.find(params[:event_id]) if params[:event_id]
    @file = @publication.publication_files.find(params[:file_id]) if params[:file_id]
  end

  def publication_params
    params.require(:publication).permit(publication_files: [])
  end

  def user_is_admin?
    return true if current_user.admin?
    redirect_to(root_path, alert: t('publications.not_authorized_message'))
  end

  def user_has_access?
    return true if current_user.admin? || current_user.publications.include?(@publication)
    redirect_to(root_path, alert: t('publications.not_authorized_message'))
  end

  def published?
    return unless @publication.published? || @publication.publication_exists?
    redirect_to edit_publication_path(@publication),
                alert: t('publications.published_message')
  end

  def create_event(event)
    new_event = Event.create(event)
    current_user.events << new_event
    @publication.events << new_event
  end
end

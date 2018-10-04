# frozen_string_literal: true

require 'osu_api/client'
require 'osu_api/person'
##
# Fetch a list of people from the Directory API based on the
# author names found in the WOS Record
class FetchAuthorsDirectoryApiJob < ApplicationJob
  # Defaults to 0
  # job_options retry: 0

  def perform(publication:, current_user: nil, previous_event: nil)
    event = previous_event || Event.create(Event::FETCH_AUTHORS_DIRECTORY_API)

    event.update(
      publication: publication,
      message: "Attempting to fetch authors from directory API at #{Time.now}",
      restartable: false,
      status: Event::STARTED[:name]
    )

    current_user.events << event if current_user

    # get author names array from WOSSR in publication
    authors = publication.web_of_science_source_record.record.authors
    found_authors = query_api(authors)
    process_found_authors(found_authors, publication)
    process_system_authors

    message = 'Found no authors for this publication in the Directory API'
    message = "Found #{found_authors.count} #{found_authors.count == 1 ? 'person' : 'people'} in Directory API." if found_authors.length
    event.completed(message: message, restartable: false)
    logger.debug "FetchAuthorsDirectoryApiJob: Publication.may_recruit_authors? #{publication[:id]} = #{publication.may_recruit_authors?}"
    publication.recruit_authors! if publication.may_recruit_authors?
  rescue StandardError => e
    msg = 'FetchAuthorsDirectoryApiJob.perform'
    NotificationManager.log_exception(logger, msg, e)
    event.error(message: "#{msg} : #{e.message}", restartable: true) if event
  end

  private

  ##
  # Query the API for each of the provided author names.
  # author_names example ['Ross, Bob', 'Lastname, Firstname M.']
  # @param Array<String> author_names - an array of author names found in web of science record
  # @returns Array<Hash<String,Array>> - a hash of author_name and found results pairs
  # @example - [{ name: 'Ross, Bob', people: [{email_address: 'blah@blah.com', ...}]}]
  def query_api(author_names)
    client = OsuApi::Client.new
    found_authors = []
    # iterate through each author and query api
    author_names.each do |a|
      people = client.directory_query(a)
      logger.debug "Found: #{people.map(&:email_address).join('; ')}"
      found_authors << { name: a, people: people } unless people.empty?
    end
    found_authors
  end

  def process_system_authors
    system_emails = [ENV['ED2_EMAIL_FROM'].split(',')].flatten
    system_emails.each do |email|
      publication.add_author_emails([{ email: email }])
    end
  end

  ##
  # Process the resulting hash of people found in the API
  # Remap the data into the proper shape that an AuthorPublication
  # looks like and provide that array to the publication method to
  # create or update the record.
  def process_found_authors(found_authors, publication)
    found_authors.each do |author|
      author_publications = author[:people].map do |person|
        {
          email: person.email_address,
          name: author[:name],
          primary_affiliation: person.primary_affiliation
        }
      end
      publication.add_author_emails(author_publications)
    end
  end
end

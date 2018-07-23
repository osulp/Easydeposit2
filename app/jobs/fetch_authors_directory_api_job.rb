# frozen_string_literal: true

##
# Fetch a list of people from the Directory API based on the
# author names found in the WOS Record
class FetchAuthorsDirectoryApiJob < ApplicationJob
  # Defaults to 0
  # job_options retry: 0

  def perform(publication:, current_user: nil, previous_job: nil)
    job = previous_job || Job.create(Job::FETCH_AUTHORS_DIRECTORY_API)

    job.update(
      publication: publication,
      message: "Attempting to fetch authors from directory API at #{Time.now}"  ,
      status: Job::STARTED[:name]
    )

    current_user.jobs << job if current_user

    # get author names array from WOSSR in publication
    authors = publication.web_of_science_source_record.record.authors
    found_authors = query_api(authors)
    process_found_authors(found_authors)

    message = 'Found no authors for this publication in the Directory API'
    message = "Found #{found_authors.count} #{found_authors.count == 1 ? 'person' : 'people'} in Directory API." if found_authors.length
    job.completed(message: message, restartable: false)
  rescue StandardError => e
    msg = 'FetchAuthorsDirectoryApiJob.perform'
    NotificationManager.log_exception(logger, msg, e)
    job.error(message: "#{msg} : #{e.message}")
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

  ##
  # Process the resulting hash of people found in the API
  # Remap the data into the proper shape that an AuthorPublication
  # looks like and provide that array to the publication method to
  # create or update the record.
  def process_found_authors(found_authors)
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

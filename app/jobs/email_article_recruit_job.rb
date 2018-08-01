class EmailArticleRecruitJob < ApplicationJob
  # Defaults to 0
  # job_options retry: 0

  def perform(publication:, current_user:, previous_job: nil)
    job = previous_job || Job.create(Job::EMAIL_ARTICLE_RECRUIT.merge(restartable: false, status: Job::STARTED[:name]))

    job.update(
      publication: publication,
      message: "Initiated by #{current_user.email}",
      restartable: false,
      status: Job::STARTED[:name]
    )

    current_user.jobs << job if current_user

    emails = [current_user.email]
    emails << publication.users.map(&:email)
    emails << publication.cas_users.map(&:email)

    ArticleRecruitMailer.with(emails: emails, user: current_user, publication: publication).published_email.deliver_now

    job.completed(
      message: "Email initiated by #{current_user.email} at #{Time.now}",
      restartable: false,
      status: Job::EMAIL[:name]
    )
  rescue => e
    msg = "EmailArticleRecruitJob.perform"
    NotificationManager.log_exception(logger, msg, e)
    job.error({restartable: true, message: "#{msg} : #{e.message}"})
  end
end

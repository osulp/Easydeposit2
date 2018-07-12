module Sidekiq
  class JobOptionsMiddleware
    def call(job_wrapper, item, queue, redis_pool)
      job = item['args'][0]['job_class'].constantize

      job.get_job_options
        .each{ |option, value| item[option] = value if item[option].nil? }

      yield
    end
  end
end

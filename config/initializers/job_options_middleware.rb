module Sidekiq
  class JobOptionsMiddleware
    def call(job_wrapper, item, queue, redis_pool)
      job = item['args'][0]['job_class'].constantize

      if job.respond_to?(:get_job_options)
        job.get_job_options
           .each { |option, value| item[option] = value if item[option].nil? }
      end

      yield
    end
  end
end

# frozen_string_literal: true

class SidekiqHelper
  def self.clear_all_jobs_for_class(job_class_name, queues = ['default'])
    clear_scheduled_jobs(job_class_name)
    clear_retry_jobs(job_class_name)
    clear_enqueued_jobs(job_class_name, queues)
  end

  def self.clear_scheduled_jobs(job_class_name)
    scheduled_set = Sidekiq::ScheduledSet.new
    scheduled_set.each do |job|
      job.delete if job.klass == job_class_name
    end
  end

  def self.clear_retry_jobs(job_class_name)
    retry_set = Sidekiq::RetrySet.new
    retry_set.each do |job|
      job.delete if job.klass == job_class_name
    end
  end

  def self.clear_enqueued_jobs(job_class_name, queues)
    queues.each do |queue_name|
      queue = Sidekiq::Queue.new(queue_name)
      queue.each do |job|
        job.delete if job.klass == job_class_name
      end
    end
  end
end

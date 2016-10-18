require 'sidekiq'
require 'tilt/erb'

require_relative 'sidekiq-scheduler/version'
require_relative 'sidekiq-scheduler/manager'

Sidekiq.configure_server do |config|

  config.on(:startup) do
    dynamic = Sidekiq::Scheduler.dynamic
    dynamic = dynamic.nil? ? config.options.fetch(:dynamic, false) : dynamic

    enabled = Sidekiq::Scheduler.enabled
    enabled = enabled.nil? ? config.options.fetch(:enabled, true) : enabled

    scheduler = config.options.fetch(:scheduler, {})
    
    schedule = config.options.fetch(:schedule, nil)
    schedule = schedule.deep_stringify_keys unless schedule.nil?

    listened_queues_only = Sidekiq::Scheduler.listened_queues_only
    listened_queues_only = listened_queues_only.nil? ? scheduler[:listened_queues_only] : listened_queues_only

    scheduler_options = {
      dynamic:   dynamic,
      enabled:   enabled,
      schedule:  schedule,
      listened_queues_only: listened_queues_only
    }

    schedule_manager = SidekiqScheduler::Manager.new(scheduler_options)
    config.options[:schedule_manager] = schedule_manager
    config.options[:schedule_manager].start
  end

  config.on(:shutdown) do
    config.options[:schedule_manager].stop
  end

end

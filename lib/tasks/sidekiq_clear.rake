# frozen_string_literal: true

namespace :sidekiq do

  desc "Clears all of the sidekiq queues"
  task clear_queues: :environment do
    Sidekiq::Queue.all.map(&:clear)
  end
end
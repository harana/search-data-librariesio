# frozen_string_literal: true

namespace :harana_index do

  desc "Generates search indexes and publishes to S3"
  task generate_search_indexes: :environment do
    PackageManager::Maven::Google.update_all_versions
  end

end

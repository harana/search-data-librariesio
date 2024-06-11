# frozen_string_literal: true

namespace :search do
  desc "Reindex everything"
  task reindex_everything: %i[reindex_repos reindex_projects]

  desc "Reindex repositories"
  task reindex_repos: %i[environment recreate_repos_index] do
    Repository.indexable.import
  end

  desc "Reindex projects"
  task reindex_projects: %i[environment recreate_projects_index] do
    Project.import query: -> { indexable }
  end

  desc "Benchmark pg_search"
  task benchmark: :environment do
    require_relative "../search_benchmark"
    SearchBenchmark.new.perform
  end
end

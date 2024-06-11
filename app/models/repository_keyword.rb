class RepositoryKeyword < ApplicationRecord
    # Associations
    belongs_to :project
  
    # Validations
    validates :keyword, presence: true

    # Method to retrieve unique keywords across all projects
    def self.unique_keywords
        RepositoryKeyword.select(:keyword).distinct.order(:keyword).pluck(:keyword)
    end

    # Find projects by keyword sorted by popularity (e.g., number of stars)
    def self.projects_sorted_by_popularity(keyword)
        RepositoryKeyword.includes(:project)
                         .where(keyword: keyword)
                         .joins(project: :repository)
                         .order('repositories.stargazers_count DESC')
                         .limit(30)
                         .map(&:project)
    end

    # Find projects by keyword sorted by the date they were last updated
    def self.projects_sorted_by_recently_updated(keyword)
        RepositoryKeyword.includes(:project)
                         .where(keyword: keyword)
                         .joins(:project)
                         .order('projects.updated_at DESC')
                         .limit(30)
                         .map(&:project)
    end

    # Find projects by keyword sorted by the date they were created
    def self.projects_sorted_by_recently_created(keyword)
        RepositoryKeyword.includes(:project)
                         .where(keyword: keyword)
                         .joins(:project)
                         .order('projects.created_at DESC')
                         .limit(30)
                         .map(&:project)
    end
end
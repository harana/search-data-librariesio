# frozen_string_literal: true

require "rails_helper"

describe "API::DocController" do
  describe "GET /api/", type: :request do
    it "renders successfully" do
      project = create(:project, name: "base62", platform: "NPM")
      create(:version, project: project)
      create(:repository, full_name: "gruntjs/grunt")
      create(:repository_user, login: "andrew")

      visit "/api"
      expect(page).to have_content "API Docs"
    end
  end
end

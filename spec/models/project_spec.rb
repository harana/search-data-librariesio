# frozen_string_literal: true

require "rails_helper"

describe Project, type: :model do
  it { should have_many(:versions) }
  it { should have_many(:dependencies) }
  it { should have_many(:contributions) }
  it { should have_many(:contributors) }
  it { should have_many(:tags) }
  it { should have_many(:dependents) }
  it { should have_many(:repository_dependencies) }
  it { should have_many(:dependent_repositories) }
  it { should have_many(:subscriptions) }
  it { should have_many(:project_suggestions) }
  it { should have_one(:readme) }
  it { should belong_to(:repository) }
  it { should have_many(:repository_maintenance_stats) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:platform) }

  describe "license normalization" do
    let(:project) { create(:project, name: "foo", platform: PackageManager::Rubygems) }

    it "handles a single license" do
      project.licenses = "mit"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(["MIT"])
      expect(project.license_normalized).to be_truthy
    end

    it "handles comma separated license" do
      project.licenses = "mit,isc"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(%w[MIT ISC])
      expect(project.license_normalized).to be_truthy
    end

    it "handles OR separated licenses" do
      project.licenses = "mit OR isc"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(%w[MIT ISC])
      expect(project.license_normalized).to be_truthy
    end

    it "handles or separated licenses" do
      project.licenses = "mit or ISC"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(%w[MIT ISC])
      expect(project.license_normalized).to be_truthy
    end

    it "handles (OR) separated licenses" do
      project.licenses = "(mit OR isc)"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(%w[MIT ISC])
      expect(project.license_normalized).to be_truthy
    end

    it "handles (OR) separated licenses" do
      project.licenses = "(MIT or CC0-1.0)"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(["MIT", "CC0-1.0"])
      expect(project.license_normalized).to be_truthy
    end

    it "handles AND separated licenses" do
      project.licenses = "mit AND ISC"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(%w[MIT ISC])
      expect(project.license_normalized).to be_truthy
    end

    it "handles and separated licenses" do
      project.licenses = "mit and ISC"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(%w[MIT ISC])
      expect(project.license_normalized).to be_truthy
    end

    it "handles exact licenses" do
      project.licenses = "MIT"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(["MIT"])
      expect(project.license_normalized).to be_falsey
    end

    it "handles long licenses" do
      project.licenses = "x" * 200
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(["Other"])
      expect(project.license_normalized).to be_truthy
    end

    it "handles unknown licenses" do
      project.licenses = "Nonsense"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(["Other"])
      expect(project.license_normalized).to be_truthy
    end

    it "disables license normalization for licenses set by admin" do
      project.normalized_licenses = ["Apache-2.0"]
      project.license_set_by_admin = true
      project.licenses = "mit"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(["Apache-2.0"])
    end

    it "handles special case Apache License, Version 2.0" do
      project.licenses = "Apache License, Version 2.0"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(["Apache-2.0"])
      expect(project.license_normalized).to be_truthy
    end

    it "handles special case Apache Software License, Version 2.0" do
      project.licenses = "The Apache Software License, Version 2.0"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(["Apache-2.0"])
      expect(project.license_normalized).to be_truthy
    end
  end

  describe "maintenance stats" do
    let!(:repository) { create(:repository) }
    let!(:project) { create(:project, repository: repository) }

    context "without existing stats" do
      it "should be included in no_existing_stats query" do
        results = Project.no_existing_stats.where(id: project.id)
        expect(results.count).to eql 1
      end
    end

    context "with stats" do
      let!(:stat1) { create(:repository_maintenance_stat, repository: repository) }

      it "should not be in no_existing_stats query" do
        results = Project.no_existing_stats.where(id: project.id)
        expect(results.count).to eql 0
      end

      it "should show up in least_recently_updated_stats query" do
        results = Project.least_recently_updated_stats.where(id: project.id)
        # count will return a hash
        # the key is the grouped column which is the project id
        # the value is the count for that project id
        expect(results.count.key?(project.id)).to be true
        expect(results.count[project.id]).to eql 1
      end
    end

    context "two projects with stats" do
      let!(:stat1) { create(:repository_maintenance_stat, repository: repository) }
      let!(:repository2) { create(:repository, full_name: "octokit/octokit") }
      let!(:project2) { create(:project, repository: repository2) }
      let!(:stat2) { create(:repository_maintenance_stat, repository: repository2) }

      before do
        stat2.update_column(:updated_at, Date.today - 1.month)
      end

      it "should return project with oldest stats first" do
        results = Project.least_recently_updated_stats
        expect(results.first.id).to eql project2.id
      end

      it "should return both projects" do
        results = Project.least_recently_updated_stats
        expect(results.length).to eql 2
      end

      it "no_existing_stats query should be empty" do
        results = Project.no_existing_stats
        expect(results.length).to eql 0
      end
    end
  end

  describe "reformat_urls" do
    let!(:project) { create(:project) }

    it "should save the updated format URL" do
      project.update!(homepage: "https://libraries.io", repository_url: "scm:git:git://github.com/librariesio/libraries.io/libaries.io.git")
      project.reformat_repository_url

      expect(project.homepage).to eql "https://libraries.io"
      expect(project.repository_url).to eql "https://github.com/librariesio/libraries.io"
    end
  end

  describe ".find_best!(platform, name, includes=[])" do
    context "with an exact match" do
      it "returns the record" do
        project = create(:project, name: "Django")
        expect(Project.find_best!(project.platform, project.name))
          .to eq(project)
      end
    end

    context "with a case-insensitive match" do
      it "returns the record" do
        project = create(:project, name: "Django")
        expect(Project.find_best!(project.platform, "django"))
          .to eq(project)
      end
    end

    context "with no match" do
      it "raises an error" do
        expect { Project.find_best!("unknown", "unknown") }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe ".find_best(platform, name, includes=[])" do
    context "with a match" do
      it "returns the record" do
        project = create(:project, name: "Django")
        expect(Project.find_best(project.platform, project.name))
          .to eq(project)
      end
    end

    context "with no match" do
      it "returns nil" do
        expect(Project.find_best("unknown", "unknown"))
          .to be_nil
      end
    end
  end

  describe "#async_sync" do
    let!(:project) { Project.create(platform: "NPM", name: "jade") }

    it "should kick off package manager download jobs" do
      expect { project.async_sync }.to change { PackageManagerDownloadWorker.jobs.size }.by(1)
    end

    it "should kick off status check job" do
      expect { project.async_sync }.to change { CheckStatusWorker.jobs.size }.by(1)
    end
  end

  describe "#check_status" do

    before { travel_to DateTime.current }

    context "entire project deprecated with message" do
      let!(:project) { Project.create(platform: "NPM", name: "jade", status: "", updated_at: 1.week.ago) }

      it "should use the result of entire_package_deprecation_info" do
        VCR.use_cassette("project/check_status/jade") do
          project.check_status

          project.reload

          expect(project.status).to eq("Deprecated")
          expect(project.deprecation_reason).not_to eq(nil)
          expect(project.status_checked_at).to eq(DateTime.current)
          expect(project.updated_at).to eq(DateTime.current)
        end
      end
    end

    context "some of project deprecated" do
      let!(:project) { Project.create(platform: "NPM", name: "react", status: nil, updated_at: 1.week.ago) }

      it "should use the result of entire_package_deprecation_info" do
        VCR.use_cassette("project/check_status/react") do
          project.check_status

          project.reload

          expect(project.status).to eq(nil)
          # Since there was no change, update status_checked_at but do not update updated_at
          expect(project.status_checked_at).to eq(DateTime.current)
          expect(project.updated_at).to eq(1.week.ago)
        end
      end
    end

    context "deprecated project no longer deprecated" do
      let!(:project) { Project.create(platform: "NPM", name: "react", status: "Deprecated", updated_at: 1.week.ago) }

      it "should mark the project no longer deprecated" do
        VCR.use_cassette("project/check_status/react") do
          project.check_status

          project.reload

          expect(project.status).to eq(nil)
          expect(project.deprecation_reason).to eq(nil)
          expect(project.status_checked_at).to eq(DateTime.current)
          expect(project.updated_at).to eq(DateTime.current)
        end
      end
    end

    context "removed project no longer removed" do
      context "when package manager can have entire package deprecated" do
        let!(:project) { Project.create(platform: "NPM", name: "react", status: "Removed") }

        it "should mark the project no longer removed" do
          VCR.use_cassette("project/check_status/react") do
            project.check_status

            project.reload

            expect(project.status).to eq(nil)
          end
        end
      end

      context "when package manager cannot have entire package deprecated" do
        let!(:project) { Project.create(platform: "Rubygems", name: "rails", status: "Removed") }

        it "should mark the project no longer removed" do
          VCR.use_cassette("project/check_status/rails") do
            project.check_status

            project.reload

            expect(project.status).to eq(nil)
          end
        end
      end
    end
  end

  describe "DeletedProject management" do
    let!(:project) { Project.create(platform: "NPM", name: "react") }

    it "should create a DeletedProject when destroyed" do
      expect(DeletedProject.count).to eq(0)
      digest = DeletedProject.digest_from_platform_and_name(project.platform, project.name)
      expect(digest).to eq("ef64ba66a6ca7f649a3e384bf2345e05698d6100b931fe14a21853a3af82900c")
      project.destroy!
      expect(DeletedProject.count).to eq(1)
      dp = DeletedProject.first
      expect(dp.digest).to eq(digest)
    end

    it "should remove a DeletedProject when resurrected" do
      expect(DeletedProject.count).to eq(0)
      digest = DeletedProject.digest_from_platform_and_name(project.platform, project.name)
      expect(digest).to eq("ef64ba66a6ca7f649a3e384bf2345e05698d6100b931fe14a21853a3af82900c")
      project.destroy!
      expect(DeletedProject.count).to eq(1)
      Project.create(platform: "NPM", name: "react")
      expect(DeletedProject.count).to eq(0)
    end
  end
  context "project_mailing_list" do
    let(:repository) { create(:repository) }
    let(:project) { create(:project, repository: repository) }

    def create_sub(user)
      Subscription.create(project: project, user: user)
    end

    def create_repo_sub(user)
      repo_sub = RepositorySubscription.create(user: user, repository: repository)
      Subscription.create(project: project, repository_subscription: repo_sub)
    end

    it "builds a version mailing list for notifications" do
      create_sub(create(:user))
      create_repo_sub(create(:user))
      expect(project.mailing_list.count).to eq 2
    end

    it "doesn't email users with disabled emails" do
      create_sub(create(:user))
      create_sub(create(:user, emails_enabled: false))

      expect(project.mailing_list.count).to eq 1
    end

    it "doesn't email users who muted project" do
      mute_user = create(:user)
      create_sub(mute_user)
      create_sub(create(:user))
      ProjectMute.create(project: project, user: mute_user)

      expect(project.mailing_list.count).to eq 1
    end
  end

  describe "latest_release" do
    let!(:project) { create(:project) }
    let!(:newer_release) { create(:version, project: project, number: "2.0.0", published_at: 1.month.ago, id: 1000, created_at: 1.year.ago) }
    let!(:older_release) { create(:version, project: project, number: "1.0.0", published_at: 1.year.ago, id: 2000, created_at: 1.month.ago) }

    it "returns the newer release as latest" do
      expect(project.latest_release).to eql(newer_release)
    end

    context "with no publish dates" do
      before do
        newer_release.update!(published_at: nil)
        older_release.update!(published_at: nil)
      end

      it "returns the latest created release" do
        expect(project.latest_release).to eql(older_release)
      end
    end

    context "with nils mixed with publish dates" do
      before do
        older_release.update!(published_at: nil)
      end

      it "returns the latest created release" do
        expect(project.latest_release).to eql(newer_release)
      end
    end

    context "with all nil published dates" do
      before do
        older_release.update!(published_at: nil)
        newer_release.update!(published_at: nil)
      end

      it "returns the latest created release" do
        expect(project.latest_release).to eql(older_release)
      end
    end
  end

  describe "manual_sync" do
    let!(:project) { create(:project, platform: "Rubygems", name: "my_gem") }

    before { allow(PackageManagerDownloadWorker).to receive(:perform_async) }

    it "sends option to sync all dependencies to download worker" do
      project.manual_sync

      expect(PackageManagerDownloadWorker).to have_received(:perform_async).with(
        "PackageManager::Rubygems",
        project.name,
        nil,
        "project",
        0,
        true
      )
    end
  end

  describe "::platform" do
    subject(:scoped_collection) { described_class.platform(given_platforms) }

    let!(:ruby1) { create(:project, :rubygems) }
    let!(:ruby2) { create(:project, :rubygems) }
    let!(:npm1) { create(:project, :npm) }

    context "mismatched case" do
      let(:given_platforms) { "RubyGems" }

      it "includes all matches" do
        expect(scoped_collection).to match_array([ruby1, ruby2])
      end
    end

    context "exact case" do
      let(:given_platforms) { "Rubygems" }

      it "includes all matches" do
        expect(scoped_collection).to match_array([ruby1, ruby2])
      end
    end

    context "other" do
      let(:given_platforms) { "foo" }

      it "is empty" do
        expect(scoped_collection).to be_empty
      end
    end

    context "multiple" do
      let(:given_platforms) { %w[RubyGems NPm] }

      it "can match any" do
        expect(scoped_collection).to match_array([ruby1, ruby2, npm1])
      end
    end
  end
end

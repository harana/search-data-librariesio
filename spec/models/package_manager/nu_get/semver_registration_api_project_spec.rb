require "rails_helper"

describe PackageManager::NuGet::SemverRegistrationApiProject do
  describe ".request" do
    context "with a deprecated release" do
      let(:project) do
        VCR.use_cassette("nu_get/api_project/entityframework_mappingapi") do
          described_class.request(project_name: "EntityFramework.MappingAPI")
        end
      end

      let(:last_release) { project.releases.last }

      it "has deprecation info" do
        expect(last_release.deprecation.alternate_package).to eq("Z.EntityFramework.Extensions")
        expect(last_release.deprecation.message).to eq("Legacy")
      end
    end

    context "with a project with releases" do
      let(:project) do
        VCR.use_cassette("nu_get/api_project/newtonsoft_json") do
          described_class.request(project_name: "NLog.Extensions.Logging")
        end
      end

      it "has no missing releases" do
        expect(project.any_missing_releases?).to eq(false)
      end

      context "with latest release" do
        # this is the newest release
        let(:last_release) { project.releases.last }

        it "has a published at time" do
          expect(last_release.published_at).to eq(Time.parse("2023-09-06 19:24:46.72 +0000"))
        end

        it "has a version" do
          expect(last_release.version).to eq("5.3.4")
        end

        it "has a project url" do
          expect(last_release.project_url).to eq("https://github.com/NLog/NLog.Extensions.Logging")
        end

        it "has a description" do
          expect(last_release.description).to eq("NLog LoggerProvider for Microsoft.Extensions.Logging for logging in .NET Standard libraries and .NET Core applications.\n\nFor ASP.NET Core, check: https://www.nuget.org/packages/NLog.Web.AspNetCore")
        end

        it "has tags" do
          expect(last_release.tags).to eq([
            "Microsoft.Extensions.Logging", "NLog", "log", "logfiles", "logging", "netcore"
          ])
        end

        it "does not have deprecation info" do
          expect(last_release.deprecation).to eq(nil)
        end

        it "has licenses" do
          expect(last_release.licenses).to eq("BSD-2-Clause")
        end

        it "has dependencies" do
          expect(last_release.dependencies.count).to eq(20)

          expect(last_release.dependencies.first.name).to eq("Microsoft.Extensions.Configuration.Abstractions")
          expect(last_release.dependencies.first.requirements).to eq(">= 2.1.0")

          expect(last_release.dependencies.last.name).to eq("NLog")
          expect(last_release.dependencies.last.requirements).to eq(">= 5.2.4")
        end
      end
    end
  end
end

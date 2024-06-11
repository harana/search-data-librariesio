# frozen_string_literal: true

module PackageManager
  class SwiftPM < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_SUPPORT = true
    URL = "https://developer.apple.com/swift/"
    COLOR = "#ffac45"
    ICON = "swift_pm.svg"

    def self.project_names
      get("https://raw.githubusercontent.com/SwiftPackageIndex/PackageList/main/packages.json")
    end

    def self.project(name)
      name_with_owner = name.gsub(/^https:\/\/github\.com\//, '').gsub(/\.git$/, '')
      {
        name: name_with_owner,
        repository_url: "https://github.com/#{name_with_owner}",
      }
    end

    def self.mapping(raw_project)
      MappingBuilder.build_hash(
        name: raw_project[:name],
        description: nil, # TODO: can we get description?
        repository_url: raw_project[:repository_url]
      )
    end
  end
end

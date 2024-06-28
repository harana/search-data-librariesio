# frozen_string_literal: true

module PackageManagers

  @@package_managers = [
    "Bower", 
    "Cargo", 
    "Carthage", 
    "Clojars", 
    "Cocoapods", 
    "Conda", 
    "CPAN", 
    "CRAN", 
    "Dub", 
    "Elm",
    "Go",
    "Hackage", 
    "Haxelib", 
    "Hex", 
    "Homebrew", 
    "Julia", 
    "Maven", 
    "Meteor", 
    "Nimble", 
    "NPM",
    "NuGet", 
    "Packagist", 
    "Pub", 
    "Puppet", 
    "PureScript", 
    "PyPi",
    "Racket", 
    "Rubygems", 
    "SwiftPM"
  ]

  def self.list 
    @@package_managers
  end

end

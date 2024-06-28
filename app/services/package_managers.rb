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

  @@mappings = {
    "Bower"         => "Javascript",
    "Cargo"         => "Rust",
    "Carthage"      => "Swift",
    "Clojars"       => "Clojure",
    "Cocoapods"     => "Swift",
    "Conda"         => "Python",
    "CPAN"          => "Perl",
    "CRAN"          => "R",
    "Dub"           => "D",
    "Elm"           => "Elm",
    "Go"            => "Go",
    "Hackage"       => "Haskell",
    "Haxelib"       => "Haxe",
    "Hex"           => "Elixir",
    "Homebrew"      => "PlainText",
    "Julia"         => "Julia",
    "Maven"         => "Java",
    "Meteor"        => "Javascript",
    "Nimble"        => "Nim",
    "NPM"           => "Javascript",
    "NuGet"         => "CSharp",
    "Packagist"     => "PHP",
    "Pub"           => "Dart",
    "Puppet"        => "Puppet",
    "PureScript"    => "PlainText",
    "PyPi"          => "Python",
    "Racket"        => "Racket",
    "Rubygems"      => "Ruby",
    "SwiftPM"       => "Swift"
  }

  def self.list 
    @@package_managers
  end

  def self.mappings 
    @@mappings
  end

end

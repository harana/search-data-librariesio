# frozen_string_literal: true

require "builder"
require "erb"
require "fileutils"

namespace :harana_website do

  package_managers = ["Bower", "Cargo", "Carthage", "Clojars", "Cocoapods", "Conda", "CPAN", "CRAN", "Dub", "Elm", "Go", "Hackage", "Haxelib", "Hex", "Homebrew", "Julia", "Maven", "Meteor", "Nimble", "NPM", "NuGet", "Packagist", "Pub", "Puppet", "PureScript", "PyPi", "Racket", "Rubygems", "SwiftPM"]

  desc "Generates home page and publishes to S3"
  task generate_home_page: :environment do
    th = TemplateHelper.new
    th.render("home.html", key1: "value1")
  end

  desc "Generates package_manager pages and publishes to S3"
  task generate_package_manager_pages: :environment do
    package_managers.each do |package_manager|
      file = File.join("output", package_manager.downcase, "index.html")
      FileUtils.mkdir_p(File.dirname(file))
      Rails.logger.info("Generating: #{file}")
      File.write(file, ERB.new(File.read("app/assets/harana/templates/package_manager.html.erb")).result_with_hash({package_manager: package_manager}))
      # HaranaS3PushWorker.perform_async(file)  
    end
  end

  desc "Generates project pages and publishes to S3"
  task generate_project_pages: :environment do
    Project.all.each do |project|
      file = File.join("output", project.file_path)
      Rails.logger.info("Generating: #{file}")
      FileUtils.mkdir_p(File.dirname(file))
      File.write(file, ERB.new(File.read("app/assets/harana/templates/library.html.erb")).result_with_hash({project: project}))
      # HaranaS3PushWorker.perform_async(file)
    end
  end

  desc "Generates tag pages and publishes to S3"
  task generate_tag_pages: :environment do
    RepositoryKeyword.unique_keywords.each do |keyword|
      puts "Generating tag page for #{keyword}"
      file = File.join("output", "tags", "#{keyword}.html")
      FileUtils.mkdir_p(File.dirname(file))
      File.write(file, ERB.new(File.read("app/assets/harana/templates/tag.html.erb")).result_with_hash({keyword: keyword}))
    end

    file = File.join("output", "tags", "index.html")
    File.write(file, ERB.new(File.read("app/assets/harana/templates/tags.html.erb")).result_with_hash({}))
  end

  desc "Generates sitemaps and publishes to S3"
  task generate_sitemaps: :environment do
    # Set up the host name for URL creation
    host = 'https://harana.dev'
    sitemap_limit = 50_000
    sitemap_index = Builder::XmlMarkup.new(indent: 2)
    sitemap_index.instruct! :xml, version: "1.0", encoding: "UTF-8"

    # Create directories
    sitemap_dir = Rails.root.join("output", "sitemap")
    FileUtils.mkdir_p(sitemap_dir)

    sitemap_index.sitemapindex xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
      Project.find_in_batches(batch_size: sitemap_limit).with_index do |projects, batch|
        # Create XML for each batch of projects
        sitemap = Builder::XmlMarkup.new(indent: 2)
        sitemap.instruct! :xml, version: "1.0", encoding: "UTF-8"
        sitemap.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do

          # Add a static URL
          sitemap.url do
            sitemap.loc "#{host}"
            sitemap.lastmod Time.now.strftime("%Y-%m-%d")
            sitemap.changefreq 'daily'
            sitemap.priority '0.9'
          end

          # Add URLs for each package manager
          package_managers.each do |package_manager|
            sitemap.url do
              sitemap.loc "#{host}/#{package_manager.downcase}"
              sitemap.lastmod Time.now.strftime("%Y-%m-%d")
              # sitemap.lastmod project.latest_release_published_at.strftime("%Y-%m-%d")
              sitemap.changefreq 'daily'
              sitemap.priority '0.7'
              end
          end

          # Add URLs for each project in the batch
          projects.each do |project|
            sitemap.url do
              sitemap.loc "#{host}/#{project.file_path}"
              sitemap.lastmod Time.now.strftime("%Y-%m-%d")
              # sitemap.lastmod project.latest_release_published_at.strftime("%Y-%m-%d")
              sitemap.changefreq 'daily'
              sitemap.priority '0.7'
              end
          end

          # Add URLs for each repository keyword
          RepositoryKeyword.unique_keywords.each do |keyword|
            sitemap.url do
              sitemap.loc "#{host}/tags/#{keyword}.html"
              sitemap.lastmod Time.now.strftime("%Y-%m-%d")
              # sitemap.lastmod project.latest_release_published_at.strftime("%Y-%m-%d")
              sitemap.changefreq 'daily'
              sitemap.priority '0.7'
              end
          end

        end

        # Save the sitemap file
        sitemap_file = sitemap_dir.join("sitemap_#{batch + 1}.xml")
        File.open(sitemap_file, 'w') { |file| 
          file.write(sitemap.target!) 
          # HaranaS3PushWorker.perform_async(file)
        }

        # Add the sitemap to the sitemap index
        sitemap_index.sitemap do
          sitemap_index.loc "#{host}/sitemap/sitemap_#{batch + 1}.xml"
          sitemap_index.lastmod Time.now.strftime("%Y-%m-%d")
        end
      end
    end

    # Save the sitemap index file
    sitemap_index_file = sitemap_dir.join("sitemap_index.xml")
    File.open(sitemap_index_file, 'w') { |file| 
      file.write(sitemap_index.target!) 
      # HaranaS3PushWorker.perform_async(file)
    }
  end

end

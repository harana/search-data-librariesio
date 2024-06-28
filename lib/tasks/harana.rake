# frozen_string_literal: true

require "builder"
require "erb"
require "fileutils"

namespace :harana do


  desc "Generates home page and publishes to S3"
  task generate_home_page: :environment do
    s3 = S3.new
    th = TemplateHelper.new
    th.render("home.html", key1: "value1")
  end

  desc "Generates package_manager pages and publishes to S3"
  task generate_package_manager_pages: :environment do
    s3 = S3.new
    PackageManager.list.each do |package_manager|
      file = Tempfile.new(package_manager.downcase)
      FileUtils.mkdir_p(File.dirname(file))
      Rails.logger.info("Generating: #{file}")
      File.write(file, ERB.new(File.read("app/assets/harana/templates/package_manager.html.erb")).result_with_hash({package_manager: package_manager}))
      s3.save_object("#{package_manager.downcase}/index.html", file, overwrite: true)
      File.delete(file)
    end
  end

  desc "Generates tag pages and publishes to S3"
  task generate_tag_pages: :environment do
    s3 = S3.new
    RepositoryKeyword.unique_keywords.each do |keyword|
      puts "Generating tag page for #{keyword}"
      file = Tempfile.new(keyword)
      FileUtils.mkdir_p(File.dirname(file))
      File.write(file, ERB.new(File.read("app/assets/harana/templates/tag.html.erb")).result_with_hash({keyword: keyword}))
      s3.save_object("tags/#{keyword}.html", file, overwrite: true)
      File.delete(file)
    end

    file = Tempfile.new("tags/index")
    File.write(file, ERB.new(File.read("app/assets/harana/templates/tags.html.erb")).result_with_hash({}))
    s3.save_object("tags/index.html", file, overwrite: true)
    File.delete(file)
  end

  desc "Generates sitemaps and publishes to S3"
  task generate_sitemaps: :environment do
    s3 = S3.new
    package_managers = PackageManagers.list

    host = 'https://harana.dev'
    sitemap_limit = 50_000
    sitemap_index = Builder::XmlMarkup.new(indent: 2)
    sitemap_index.instruct! :xml, version: "1.0", encoding: "UTF-8"

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
        sitemap_name = "sitemap_#{batch + 1}.xml"
        file = Tempfile.new(sitemap_name)
        File.open(file, 'w') { |file| 
          file.write(sitemap.target!)
          s3.save_object("sitemap/#{sitemap_name}", file, overwrite: true)
        }
        File.delete(file)

        # Add the sitemap to the sitemap index
        sitemap_index.sitemap do
          sitemap_index.loc "#{host}/sitemap/sitemap_#{batch + 1}.xml"
          sitemap_index.lastmod Time.now.strftime("%Y-%m-%d")
        end
      end
    end

    # Save the sitemap index file
    file = Tempfile.new("sitemap_index")
    File.open(sitemap_index_file, 'w') { |file| 
      file.write(sitemap_index.target!)
      s3.save_object("sitemap/index.xml", file, overwrite: true)
    }
    File.delete(file)
  end
end
# Originally from http://tumble.mlcastle.net/post/17704454324/a-lightweight-migrations-system-for-couchrestrails

require File.expand_path("../../server/sinatra/stores/couch.rb", File.dirname(__FILE__))

namespace :couch do

  desc "Perform unperformed CouchDB migrations"
  # Run with foreman, eg ::: foreman run rake couch:migrate --trace
  task :migrate do
    schema = CouchStore.get_or_create_design("migration-list")

    migrations = Rake::Task.tasks.select { |t| t.name =~ /^couch:migrations:/ }

    begin
      migrations.sort { |a, b| a.name <=> b.name }.each do |migration|
        unless schema[migration.to_s]
          puts
          puts "== running #{migration.to_s}"

          migration.invoke

          schema[migration.to_s] = true
        end
      end
    ensure
      schema.save
    end
  end

end

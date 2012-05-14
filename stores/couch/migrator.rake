# Originally from http://tumble.mlcastle.net/post/17704454324/a-lightweight-migrations-system-for-couchrestrails

desc "Perform unperformed CouchDB migrations"
task :migrate => :environment do
  schema = begin
    CouchRestRails::Document.get("migration-list")
  rescue RestClient::ResourceNotFound
    CouchRestRails::Document.new(:_id => "migration-list")
  end

  # there HAS to be a better way to get all the tasks in a namespace, but
  # I can't find one.
  migrations = Rake::Task.tasks.select { |t| t.name =~ /^migrations:/ }

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
require 'time'  # for Time.now.iso8601

$couch = CouchRest.database!("#{ENV['COUCHDB_URL'] || raise('please set ENV["COUCHDB_URL"]')}/sfw")

begin
  $couch.save_doc "_id" => "_design/recent-changes", :views => {}
rescue RestClient::Conflict
  # design document already exists, do nothing
end


#module FederatedWiki
#  module Store
#    module CouchDB
#
#    end
#  end
#end

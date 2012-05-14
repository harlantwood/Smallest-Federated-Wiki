require 'time'  # for Time#iso8601
require "rest-client"
require "couchrest"

require File.expand_path("store.rb", File.dirname(__FILE__))

class CouchStore < Store
  class << self

    attr_writer :db   # used by specs

    def db
      unless @db
        couchdb_server = ENV['COUCHDB_URL'] || raise('please set ENV["COUCHDB_URL"]')
        @db = CouchRest.database!("#{couchdb_server}/sfw")
      end
      @db
    end

    ### GET

    def get_text(path)
      path = relative_path(path)
      begin
        db.get(path)['data']
      rescue RestClient::ResourceNotFound
        nil
      end
    end

    def get_blob(path)
      blob = get_text path
      Base64.decode64 blob if blob
    end

    ### PUT

    def put_text(path, text, metadata={})
      path = relative_path(path)
      metadata = metadata.each{ |k,v| metadata[k] = relative_path(v) }
      attrs = {
        'data' => text,
        'updated_at' => Time.now.utc.iso8601
      }.merge! metadata

      begin
        db.save_doc attrs.merge('_id' => path)
      rescue RestClient::Conflict
        doc = db.get path
        doc.merge! attrs
        doc.save
      end
      text
    end

    def put_blob(path, blob)
      put_text path, Base64.strict_encode64(blob)
      blob
    end

    ### COLLECTIONS

    def page_metadata(_, max_pages)
      pages = db.view("pages-metadata/all")['rows']

      data = pages.map do |page_doc|
        {
          'updated_at' => Time.parse(page_doc['value'][0]),
          'site' => page_doc['value'][1],
          'name' => page_doc['value'][2]
        }
      end

      data[0...max_pages]
    end

    def annotated_pages(pages_dir = nil, options={})
      pages(pages_dir).map do |page_doc|
        page = options[:skip_body] ? {} : JSON.parse(page_doc['value']['data'])
        page['updated_at'] = Time.parse(page['updated_at'] || page_doc['value']['updated_at'] )
        page.merge! 'site' => page_doc['value']['site']
        page.merge! 'name' => page_doc['value']['name']
        page
      end
    end

    ### VIEWS

    def pages(pages_dir)
      pages_dir = relative_path pages_dir
      pages_dir_safe = CGI.escape pages_dir
      begin
        db.view("pages/#{pages_dir_safe}")['rows']
      rescue RestClient::ResourceNotFound
        create_view 'pages-with-dir', pages_dir
        db.view("pages-with-dir/#{pages_dir_safe}")['rows']
      end
    end

    def create_view(design_name, view_name)
      design = get_or_create_design design_name
      design['views'][view_name] = {
        :map => "
          function(doc) {
            if (doc.type == 'Page' && doc.directory == '#{view_name}')
              emit(doc._id, doc)
          }
        "
      }
      design.save
    end

    def get_or_create_design(design_name)
      # TODO: if we are in dev mode, always update views -- otherwise view changes never get pushed!
      begin
        db.get "_design/#{design_name}"
      rescue RestClient::ResourceNotFound
        begin
          @db.save_doc "_id" => "_design/#{design_name}", :views => {}
        rescue RestClient::Conflict
          # don't explode in the case that another thread has created this design document at the same time
        end
        db.get "_design/#{design_name}"
      end
    end

    ### UTILITY

    def farm?(_)
      !!ENV['FARM_MODE']
    end

    def mkdir(_)
      # do nothing
    end

    def exists?(path)
      !(get_text path).nil?
    end

    def relative_path(path)
      raise "Please set @app_root" unless @app_root
      path.match(%r[^#{Regexp.escape @app_root}/?(.+?)$]) ? $1 : path
    end

  end

end



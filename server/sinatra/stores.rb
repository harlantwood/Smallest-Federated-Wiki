require 'time'  # for Time#iso8601


class Store
  class << self
    def select(store_classname)
      store_classname ? Kernel.const_get(store_classname) : FileStore
    end

    ### GET

    def get_hash(path)
      json = get_text path
      JSON.parse json if json
    end

    alias_method :get_page, :get_hash

    ### PUT

    def put_hash(path, ruby_data, metadata={})
      json = JSON.pretty_generate(ruby_data)
      put_text path, json, metadata
      ruby_data
    end

    alias_method :put_page, :put_hash

  end
end


class FileStore < Store
  class << self

    ### GET

    def get_text(path)
      File.read path if File.exist? path
    end

    alias_method :get_blob, :get_text

    ### PUT

    def put_text(path, text, _)
      # Note: the third argument, metadata, is ignored for filesystem storage
      File.open path, 'w' do |file|
        file.write text
      end
      text
    end

    def put_blob(path, blob)
      File.open path, 'wb' do |file|
        file.write blob
      end
      blob
    end

    ### COLLECTIONS

    def recently_changed_pages(pages_dir)
      Dir.chdir(pages_dir) do
        Dir.glob("*").collect do |name|
          page = get_page(File.join pages_dir, name)
          page.merge!({
            'name' => name,
            'updated_at' => File.new(name).mtime
          })
        end
      end
    end

    ### UTILITY

    def farm?(data_root)
      File.exists?(File.join data_root, "farm")
    end

    def mkdir(directory)
      FileUtils.mkdir_p directory
    end

    def exists?(path)
      File.exists?(path)
    end
  end
end


class CouchStore < Store
  class << self

    def db
      unless @db
        couchdb_server = ENV['COUCHDB_URL'] || raise('please set ENV["COUCHDB_URL"]')
        @db = CouchRest.database!("#{couchdb_server}/SFW")
        begin
          @db.save_doc "_id" => "_design/recent-changes", :views => {}
        rescue RestClient::Conflict
          # design document already exists, do nothing
        end
      end
      @db
    end

    def db=(db)
      @db = db
    end

    ### GET

    def get_text(path)
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

    def recently_changed_pages(pages_dir)
      pages_dir_safe = CGI.escape pages_dir
      changes = begin
        db.view("recent-changes/#{pages_dir_safe}")['rows']
      rescue RestClient::ResourceNotFound
        create_view 'recent-changes', pages_dir
        db.view("recent-changes/#{pages_dir_safe}")['rows']
      end

      pages = changes.map do |change|
        page = JSON.parse change['value']['data']
        page.merge! 'updated_at' => Time.parse(change['value']['updated_at'])
        page.merge! 'name' => change['value']['name']
        page
      end

      pages
    end

    ### UTILITY

    def create_view(design_name, view_name)
      design = db.get "_design/#{design_name}"
      design['views'][view_name] = {
        :map => "
          function(doc) {
            if (doc.directory == '#{view_name}')
              emit(doc._id, doc)
          }
        "
      }
      design.save
    end

    def farm?(_)
      ENV['FARM_MODE'] && !ENV['FARM_MODE'].empty?
    end

    def mkdir(_)
      # do nothing
    end

    def exists?(path)
      !(get_text(path)).nil?
    end

  end

end



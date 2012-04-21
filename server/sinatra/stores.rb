require 'time'  # for Time#iso8601


class Store
  class << self
    def factory(store_classname)
      store_classname ? Object.const_get(store_classname) : FileStore
    end
  end
end


class FileStore
  class << self

    ### GET

    def get_text(path)
      File.read path if File.exist? path
    end

    alias_method :get_blob, :get_text

    def get_hash(path)
      json = get_text(path)
      JSON.parse json if json
    end

    alias_method :get_page, :get_hash

    ### PUT

    def put_text(path, text)
      File.open(path, 'w') { |file| file.write(text) }
      text
    end

    def put_blob(path, blob)
      File.open path, 'wb' do |file|
        file.write blob
      end
      blob
    end

    def put_hash(path, ruby_data)
      put_text path, JSON.pretty_generate(ruby_data)
      ruby_data
    end

    def put_page(path, page, metadata)
      # note: metadata is ignored in FileStore
      put_hash(path, page)
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

  end
end


class CouchStore
  class << self
    attr_writer :db

    #def db
    #  @db = CouchRest.database!("#{ENV['COUCHDB_URL'] || raise('please set ENV["COUCHDB_URL"]')}/sfw")
    #end

    ### GET

    def get_text(path)
      begin
        @db.get(path)['data']
      rescue RestClient::ResourceNotFound
        nil
      end
    end

    def get_blob(path)
      blob = get_text path
      Base64.decode64 blob if blob
    end

    def get_hash(path)
      json = get_text path
      JSON.parse json if json
    end

    alias_method :get_page, :get_hash

    ### PUT

    def put_text(path, text, metadata={})
      attrs = {
        'data' => text,
        'updated_at' => Time.now.utc.iso8601
      }.merge! metadata

      begin
        @db.save_doc attrs.merge('_id' => path)
      rescue RestClient::Conflict
        doc = @db.get path
        doc.merge attrs
        doc.save
      end
      text
    end

    def put_hash(path, ruby_data, metadata={})
      json = JSON.pretty_generate(ruby_data)
      put_text path, json, metadata
      ruby_data
    end

    alias_method :put_page, :put_hash

    def put_blob(path, blob)
      put_text path, Base64.strict_encode64(blob)
      blob
    end

    ### COLLECTIONS

    def recently_changed_pages(pages_dir)

      pages_dir_safe = CGI.escape pages_dir
      changes = begin
        @db.view("recent-changes/#{pages_dir_safe}")['rows']
      rescue RestClient::ResourceNotFound
        recent_changes_views = @db.get "_design/recent-changes"
        recent_changes_views['views'][pages_dir] = {
          :map => "
            function(doc) {
              if (doc.directory == '#{pages_dir}')
                emit(doc._id, doc)
            }
          "
        }
        recent_changes_views.save
        @db.view("recent-changes/#{pages_dir_safe}")['rows']
      end

      pages = changes.map do |change|
        page = JSON.parse change['value']['data']
        page.merge! 'updated_at' => Time.parse(change['value']['updated_at'])
        page.merge! 'name' => change['value']['name']
        page
      end

      pages
    end

  end

end



require 'time'  # for Time#iso8601


class Store
  class << self
    def factory(store_classname)
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

    ### UTILITY

    def exists?(path)
      result = get_text path
      result && !result.empty?
    end

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
        create_view 'recent-changes', pages_dir
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

    ### UTILITY

    def create_view(design_name, view_name)
      design = @db.get "_design/#{design_name}"
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

  end

end



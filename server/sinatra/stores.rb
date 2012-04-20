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

    def get_json(path)
      json = get_text(path)
      JSON.parse json if json
    end

    alias_method :get_page, :get_json

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

    def put_json(path, json)
      put_text(path, json)
      JSON.parse json
    end

    def put_page(path, text, metadata)
      # note: metadata is ignored in FileStore
      put_json(path, text)
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

    def get_json(path)
      json = get_text path
      JSON.parse json if json
    end

    alias_method :get_page, :get_json

    ### PUT

    def put_text(path, text, metadata={})
      attrs = {
        'data' => text,
        'updated_at' => Time.now.iso8601
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

    def put_json(path, json, metadata)
      put_text path, json, metadata
      JSON.parse json
    end

    alias_method :put_page, :put_json

    def put_blob(path, blob)
      put_text path, Base64.strict_encode64(blob)
      blob
    end

  end

end



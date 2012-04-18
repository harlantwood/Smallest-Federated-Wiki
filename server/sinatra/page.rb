require 'json'
require File.expand_path("../random_id", __FILE__)
require File.expand_path("../store/couchdb", __FILE__)

class PageError < StandardError; end;

# Page Class
# Handles writing and reading JSON data to and from files.
class Page
  # class << self
    # Directory where pages are to be stored.
    attr_accessor :directory
    # Directory where default (pre-existing) pages are stored.
    attr_accessor :default_directory

    # Get a page
    #
    # @param [String] name - The name of the file to retrieve, relative to Page.directory.
    # @return [Hash] The contents of the retrieved page (parsed JSON).
    def get(name)
      assert_directories_set
      path = File.join(directory, name)
      begin
        JSON.parse($couch.get(path)['data'])
      rescue RestClient::ResourceNotFound
        default_path = File.join(default_directory, name)
        if File.exist?(default_path)
          put name, JSON.parse(File.read(default_path))
        else
          put name, {'title'=>name,'story'=>[{'type'=>'factory', 'id'=>RandomId.generate}]}
        end
      end
    end

    def exists?(name)
      File.exists?(File.join(directory, name)) or File.exist?(File.join(default_directory, name))
    end

    # Create or update a page
    #
    # @param [String] name - The name of the file to create/update, relative to Page.directory.
    # @param [Hash] page - The page data to be written to the file (it will be converted to JSON).
    # @return [Hash] The contents of the retrieved page (parsed JSON).
    def put(name, page)
      assert_directories_set
      path = File.join directory, name
      begin
        $couch.save_doc(
          '_id' => path,
          'directory' => directory,
          'data' => JSON.pretty_generate(page),
          'updated_at' => Time.now.iso8601
        )
      rescue RestClient::Conflict
        doc = $couch.get path
        doc['data'] = JSON.pretty_generate(page)
        doc.save
      end
      page
    end

    private

    def assert_directories_set
      raise PageError.new('Page.directory must be set') unless directory
      raise PageError.new('Page.default_directory must be set') unless default_directory
    end
  # end
end

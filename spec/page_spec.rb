require File.dirname(__FILE__) + '/spec_helper'

describe "Page" do
  before(:all) do
    @page = Page.new
    @page.store = FileStore
    @page.directory = nil
    @page.default_directory = nil
  end

  context "when @page.directory has not been set" do
    it "raises PageError" do
      expect {
        @page.get('anything')
      }.to raise_error(PageError, /Page\.directory/)
    end
  end

  context "when @page.default_directory has not been set" do
    it "raises PageError" do
      @page.directory = 'tmp'
      expect {
        @page.get('anything')
      }.to raise_error(PageError, /Page\.default_directory/)
    end
  end

  context "when Page directories have been set" do
    before(:all) do
      @root = File.expand_path(File.join(File.dirname(__FILE__), ".."))
      @test_data_dir = File.join(@root, 'spec/data')
      @page.directory = @test_data_dir
      @page.default_directory = File.join(@test_data_dir, 'defaults')
    end

    before(:each) do
      FileUtils.rm_rf @page.directory
      FileUtils.mkdir @page.directory
      FileUtils.mkdir @page.default_directory
      @page_data = {'foo' => 'bar'}
    end

    def page_path(name)
      File.join(@test_data_dir, name)
    end

    describe "put" do
      def simple_get(name)
        JSON.parse(File.read(page_path(name)))
      end

      context "when page doesn't exist yet" do
        it "creates a new page with the correct data" do
          File.should_not exist(page_path('foo'))
          @page.put('foo', @page_data)
          File.should exist(page_path('foo'))
          simple_get('foo').should == @page_data
        end

        it "returns the page data" do
          @page.put('foo', @page_data).should == @page_data
        end
      end

      context "when page already exists" do
        it "updates the page" do
          @page.put('foo', @page_data)
          new_data = {'buzz' => 'fuzz'}
          @page.put('foo', new_data)
          simple_get('foo').should == new_data
        end
      end
    end

    describe "get" do

      def simple_put(name, page)
        File.open(page_path(name), 'w'){|file| file.write(page.to_json)}
      end

      context "when page exists" do
        it "returns the page" do
          simple_put 'foo', @page_data
          @page.get('foo').should == @page_data
        end
      end

      context "when page does not exist" do
        it "creates a factory page" do
          RandomId.stub(:generate).and_return('fake-id')
          foo_data = @page.get('foo')
          foo_data['title'].should == 'foo'
          foo_data['story'].first['id'].should == 'fake-id'
          foo_data['story'].first['type'].should == 'factory'
        end
      end

      context "when page does not exist, but default with same name exists" do
        it "copies default page to new page path and returns it" do
          default_data = {'default' => 'data'}
          @page.put('defaults/foo', default_data)
          @page.get('foo').should == default_data
        end
      end
    end
  end
end

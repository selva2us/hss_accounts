require 'hss'
require 'artifice'

describe "Hss::Service" do

  LSP = File.expand_path('../lsp.jpg', __FILE__)

  describe "when initializing with an invalid api_url" do
    it "should raise an error" do
      expect { Hss::Service.new("www.example.com", "/some/random/path") }.to raise_error
    end
  end

  describe "when initializing with no read url" do
    let(:service) { Hss::Service.new("http://www.example.com", "/some/random/path") }
    
    subject { service }

    its(:read_url) { should == service.api_url }
  end

  describe "when a save succeeds" do
    app = proc do |env|
        [200, {}, ["abcdef123456"] ]
    end

    before { Artifice.activate_with(app) }
    after { Artifice.deactivate }

    let(:service) { Hss::Service.new("http://www.example.com", "/some/random/path", 'http://www.read.com') }

    it "should return a url for the image" do
      service.save(File.read(LSP), 'image/jpg').should == 'http://www.read.com/some/random/path/abcdef123456'
    end
  end

  describe "when a save fails" do
    app = proc do |env|
        [404, {}, ["abcdef123456"] ]
    end

    before { Artifice.activate_with(app) }
    after { Artifice.deactivate }

    let(:service) { Hss::Service.new("http://www.example.com", "/some/random/path", 'http://www.read.com') }

    it "should throw a runtime error" do
      expect { service.save(File.read(LSP), 'image/jpg') }.to raise_error
    end
  end 

  describe "when a delete succeeds" do
    app = proc do |env|
        [200, {}, [] ]
    end

    before { Artifice.activate_with(app) }
    after { Artifice.deactivate }

    let(:service) { Hss::Service.new("http://www.example.com", "/some/random/path", 'http://www.read.com') }

    it "should return a url for the image" do
      service.delete('http://www.read.com/some/random/path/abcdef123456').should be_nil
    end
  end

  describe "when a save fails" do
    app = proc do |env|
        [500, {}, ["abcdef123456"] ]
    end

    before { Artifice.activate_with(app) }
    after { Artifice.deactivate }

    let(:service) { Hss::Service.new("http://www.example.com", "/some/random/path", 'http://www.read.com') }

    it "should throw a runtime error" do
      expect { service.delete('http://www.read.com/some/random/path/abcdef123456') }.to raise_error
    end
  end

  describe "when importing a valid photo" do
    app = proc do |env|
        [200, {"Content-Type" => "image/jpg"}, [File.read(LSP)] ]
    end

    before { Artifice.activate_with(app) }
    after { Artifice.deactivate }

    let(:service) { Hss::Service.new("http://www.example.com", "/some/random/path", 'http://www.read.com') }    

    it "should return success" do
      service.stub(:save).and_return("http://www.example.com/123")
      service.import("http://lsp.com/photo.jpg").should == "http://www.example.com/123"
    end
  end

  describe "when importing a photo that redirects less than max" do
    let(:the_hss_url) { "http://www.hssurl.com/123" }
    let(:image_type) { "image/jpg" }
    let(:contents) { "not a photo" }
    let(:app) do 
      count = 0

      proc do |env|
        count += 1
        if count == 5
          [200, {"Content-Type" => image_type}, [contents]] if count == 5
        else
          [302, {"Location" => "http://www.redirecturl.com/"}, [""]]
        end
      end
    end

    before { Artifice.activate_with(app) }
    after { Artifice.deactivate }

    let(:service) { Hss::Service.new("http://www.example.com", "/some/random/path", 'http://www.read.com') }    

    it "it should save the photo" do
      service.stub(:save).with(contents, image_type).and_return(the_hss_url)
      service.import("http://lsp.com/photo.jpg", 5).should == the_hss_url
    end
  end

  describe "when importing a photo that redirects more than max" do
    let(:the_max_redirects) { 5 }
    let(:app) do 
      [302, {"Location" => "http://www.redirecturl.com/"}, [""]]
    end

    before { Artifice.activate_with(app) }
    after { Artifice.deactivate }

    let(:service) { Hss::Service.new("http://www.example.com", "/some/random/path", 'http://www.read.com') }    

    it "it should raise an error" do
      expect { service.import("http://lsp.com/photo.jpg", the_max_redirects) }.to raise_error
    end
  end    
end 
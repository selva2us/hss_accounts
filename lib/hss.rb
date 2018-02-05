require 'ostruct'
require 'net/http'

# Public: HSS module for access to AOL's HTTP Storage Service.
module Hss

  # Public: HSS service object for saving and deleting of files.
  class Service
    attr_accessor :api_url, :read_url, :app_path

    # Public: Duplicate some text an arbitrary number of times.
    #
    # api_url - the api end point
    # read_url - hopefully a cdn to the image
    # app_path - the app storage path
    #
    # Examples
    #
    #   Hss::Service.new('http://hss-load.hss.aol.com', 'http://o.aolcdn.com', '/hss/storage/mq-accounts')
    #   # => Service
    #
    # Returns the duplicated String.
    def initialize(api_url, app_path, read_url = nil)
      @api_url = api_url
      @app_path = app_path
      @read_url = read_url || api_url

      raise ArgumentError, "API URL is required" if (@api_url =~ URI::regexp).nil?
      raise ArgumentError, "Read URL is required" if (@read_url =~ URI::regexp).nil?
    end

    # Public: Posts the file to HSS. Returns the results of the call which is the id, if successful, otherwise raises an error.
    #
    # file - the file to be stored in HSS
    # content_type - what are we storing
    #
    # Examples
    #
    #   service.save(file, 'image/png')
    #   # => 'http://example.com/path/to/image.png'
    #
    # Returns the duplicated String.
    def save(file, content_type)
      post_uri = URI(@api_url + @app_path)

      request = Net::HTTP::Post.new(post_uri.path, {'Content-Type' => content_type})
      request.body = file

      response = Net::HTTP.start(post_uri.host, post_uri.port) do |http|
        http.request(request)
      end

      case response
        when Net::HTTPSuccess
          "#{@read_url + @app_path}/#{response.body}"
        else
          raise "Unable to connect HSS (#{api_url})"
      end
    end

    # Public: Duplicate some text an arbitrary number of times. If
    #
    # url - the url of the resource to deleted
    #
    # Examples
    #
    #   service.delete('http://example.com/path/to/image.png')
    #
    # Returns the duplicated String.
    def delete(uri)
      path = extract_path(uri)
      delete_uri = URI(@api_url + path)
      request = Net::HTTP::Delete.new delete_uri.request_uri

      response = Net::HTTP.start(delete_uri.hostname, delete_uri.port) do |http|
        http.request request
      end

      raise "Error trying to delete: #{response.code} - #{response.message}" unless response.is_a?(Net::HTTPSuccess)
    end

    # Public: Imports a photo from a URI into HSS.
    #
    # uri - the URI of the image to be imported
    # max_redirects - maximum number of redirects before we implode
    #
    # Examples
    #
    #   multiplex('Tom', 4)
    #   # => 'TomTomTomTom'
    #
    # Returns the duplicated String.
    def import(uri, max_redirects = 5)
      raise ArgumentError, "Max redirects reached" if max_redirects == 0

      response = Net::HTTP.get_response(URI(uri))
      case response
        when Net::HTTPSuccess then
          self.save(response.body, response.content_type)
        when Net::HTTPRedirection then
          location = URI(response['location'])
          self.import(location, max_redirects - 1)
        else
          raise "Unable to import image, URI #{uri} returned a #{response.code}"
      end
    end

    private

    # Public: Returns the path from the URI.
    def extract_path(uri)
      case uri
        when String
          URI(uri).path
        when URI
          uri.path
        else
          raise ArgumentError, "Don't know how to extract the path from #{uri}"
      end
    end
  end
end

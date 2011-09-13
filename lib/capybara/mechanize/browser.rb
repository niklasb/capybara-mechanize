require 'capybara'
require 'mechanize'
require 'uri'
require 'nokogiri'

class Capybara::Mechanize::Browser
  extend Forwardable

  def_delegator :agent, :scheme_handlers
  def_delegator :agent, :scheme_handlers=

  attr_reader :agent

  def initialize(driver)
    @agent = ::Mechanize.new
    @agent.redirect_ok = true
    @agent.follow_meta_refresh = true
    @agent.user_agent = default_user_agent
  end

  def visit(path, attributes = {})
    request(:get, path, attributes)
  end

  def submit(method, path, attributes = {})
    path = response.url if path.nil? or path.empty?
    request(method, path, attributes)
  end

  def follow(method, path, attributes = {})
    request(method, path, attributes)
  end

  def body
    dom.to_xml
  end

  def source
    response.body
  end

  def reset_dom!
    @dom = nil
  end

  def dom
    @dom ||= Nokogiri::HTML(source)
  end

  def find(selector)
    dom.xpath(selector).map { |node|
      Capybara::RackTest::Node.new(self, node) }
  end

  protected

  attr_reader :response

  def prepare_url(path)
    base = response ? response.url.to_s : ""
    URI.join(base, path.to_s).to_s
  end

  def request(method, url, attributes = {}, headers = {})
    url = prepare_url(url)
    attributes = prepare_arguments(attributes)
    begin
      args = []
      args << attributes unless attributes.empty?
      args << headers unless headers.empty?
      @agent.send(method, url, *args)
      @response = ResponseProxy.new(@agent.current_page)
    rescue
      raise "Error while #{method.to_s.upcase}ing #{url}: #{$!}"
    end
    reset_dom!
  end

  def prepare_arguments(params)
    params.inject({}) do |memo, param|
      case param
      when Hash
        param.each {|attribute, value| memo[attribute] = value }
        memo
      when Array
        case param.last
        when Hash
          param.last.each {|attribute, value| memo["#{param.first}[#{attribute}]"] = value }
        else
          memo[param.first] = param.last
        end
        memo
      end
    end
  end

  def default_user_agent
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_0) "+
    "AppleWebKit/535.2 (KHTML, like Gecko) "+
    "Chrome/15.0.853.0 Safari/535.2"
  end

  class ResponseProxy
    extend Forwardable

    def_delegator :page, :body
    attr_reader :page

    def initialize(page)
      @page = page
    end

    def url
      page.uri.to_s
    end

    def headers
      page.response
    end

    def status
      page.code.to_i
    end

    def redirect?
      [301, 302].include?(status)
    end
  end
end


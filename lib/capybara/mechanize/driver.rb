require "capybara"
require 'capybara/mechanize/browser'

class Capybara::Mechanize::Driver < Capybara::Driver::Base
  extend Forwardable

  def_delegators :browser, :find,
                           :source,
                           :body,
                           :dom

  def initialize(app = nil, options = {})
    @app
    @options = app, options
    @rack_server = Capybara::Server.new(@app)
    @rack_server.boot if Capybara.run_server
  end

  def browser
    @browser ||= Capybara::Mechanize::Browser.new(self)
  end

  def current_url
    response && response.url
  end

  def status_code
    response && response.status
  end

  def response_headers
    response && response.headers
  end

  def visit(path)
    browser.visit(prepare_url(path))
  end

  def submit(method, path, attributes)
    browser.submit(method, prepare_url(path), attributes)
  end

  def follow(method, path, attributes = {})
    browser.follow(method, prepare_url(path), attributes)
  end

  def wait?
    true
  end

  def server_port
    @rack_server.port
  end

  def reset!
    @browser = nil
  end

  def response
    browser.response
  end

  protected

  def prepare_url(path)
    @rack_server.url(path)
  end

end

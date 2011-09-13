require 'capybara/mechanize/driver'

Capybara.register_driver :mechanize do |app|
  Capybara::Mechanize::Driver.new(app)
end

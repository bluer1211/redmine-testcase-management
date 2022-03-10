# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

def assert_flash_error(message)
  assert_equal message, flash[:error]
  assert_select "div#flash_error" do |div|
    assert_equal message, div.text
  end
end

def assert_contextual_link(label, path)
  assert_select "div#content div.contextual a:first-child" do |a|
    assert_equal path, a.first.attributes["href"].text
    assert_equal label, a.text
  end
end

def assert_back_to_lists_link(path)
  assert_select "div#content a" do |a|
    assert_equal path, a.first.attributes["href"].text
    assert_equal I18n.t(:label_back_to_lists), a.text
  end
end



require File.expand_path('../../test_helper', __FILE__)

class TestCaseAttachmentTest < ActiveSupport::TestCase

  fixtures :projects, :users, :members, :roles, :issue_statuses
  fixtures :test_cases

  def test_initialize
    test_case_attachment = TestCaseAttachment.new
    assert_nil test_case_attachment.id
    assert_nil test_case_attachment.container_id
    assert_nil test_case_attachment.container_type
  end
end

require File.expand_path('../../test_helper', __FILE__)

class TestCaseAttachmentTest < ActiveSupport::TestCase

  fixtures :projects, :users, :members, :roles, :issue_statuses
  fixtures :test_projects, :test_plans, :test_cases, :test_case_executions, :test_case_attachments

  def test_initialize
    test_case_attachment = TestCaseAttachment.new
    assert_nil test_case_attachment.id
    assert_nil test_case_attachment.container_id
    assert_nil test_case_attachment.container_type
  end

  def test_create
    test_case_attachment = TestCaseAttachment.new(:container => test_cases(:test_cases_001),
                                                  :file => uploaded_test_file("testfile.txt", "text/plain"),
                                                  :author => users(:users_001))
    assert_save test_case_attachment
    assert test_case_attachment.destroy
  end

  def test_not_unique
    test_case_attachment = TestCaseAttachment.new(:id => test_case_attachments(:test_case_attachments_001).id,
                                                  :container => test_cases(:test_cases_001),
                                                  :file => uploaded_test_file("testfile.txt", "text/plain"),
                                                  :author => users(:users_001))
    assert_raises ActiveRecord::RecordNotUnique do
      assert_save test_case_attachment
    end
  end

  def test_missing_container
    object = TestCaseAttachment.new(:file => uploaded_test_file("testfile.txt", "text/plain"),
                                    :author => users(:users_001))
    assert_equal true, object.valid?
    assert_equal [], object.errors[:container]
  end

  def test_missing_file
    object = TestCaseAttachment.new(:container => test_cases(:test_cases_001),
                                    :author => users(:users_001))
    assert object.invalid?
    assert_equal ["cannot be blank"], object.errors[:filename]
  end

  def test_missing_author
    object = TestCaseAttachment.new(:container => test_cases(:test_cases_001),
                                    :file => uploaded_test_file("testfile.txt", "text/plain"))
    assert object.invalid?
    assert_equal ["cannot be blank"], object.errors[:author]
  end

  def test_association
    test_case = test_cases(:test_cases_002)
    assert_equal test_case.id, test_case.test_case_attachments.pluck(:container_id)
  end
end

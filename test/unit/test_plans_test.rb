require File.expand_path('../../test_helper', __FILE__)

class TestPlansTest < ActiveSupport::TestCase

  fixtures :projects, :users, :members, :roles

  def test_initialize
    test_plan = TestPlans.new

    assert_nil test_plan.id
    assert_nil test_plan.name
    assert_nil test_plan.begin_date
    assert_nil test_plan.end_date
    assert_nil test_plan.estimated_bug
  end
end

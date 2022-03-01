module TestPlansHelper
  def test_plan_destroy_confirmation_message(test_plan)
    "Delete #{test_plan.name}"
  end
end

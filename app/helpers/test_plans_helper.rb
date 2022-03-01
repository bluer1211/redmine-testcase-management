module TestPlansHelper
  def test_plan_destroy_confirmation_message(test_plan)
    message = "#{test_plan.name}\n"
    message << l(:text_test_plan_destroy_confirmation)
    message
  end
end

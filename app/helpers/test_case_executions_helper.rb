module TestCaseExecutionsHelper
  include ApplicationsHelper

  def test_case_destroy_confirmation_message(test_case_execution)
    message = "#{test_case_execution.test_case.name}\n"
    message << l(:text_test_case_execution_destroy_confirmation)
    message
  end
end

module TestCasesHelper
  include ApplicationsHelper

  def test_case_destroy_confirmation_message(test_case)
    message = "#{test_case.name}\n"
    message << l(:text_test_case_destroy_confirmation)
    message
  end
end

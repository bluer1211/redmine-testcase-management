module TestPlansHelper
  include ApplicationsHelper

  def test_plan_destroy_confirmation_message(test_plan)
    message = "#{test_plan.name}\n"
    message << l(:text_test_plan_destroy_confirmation)
    message
  end

  def breadcrumb
    links = []

    links << link_to(l(:label_test_plans),
                     project_test_plans_path)
    links << "&gt;"

    links.join(" ").html_safe
  end
end

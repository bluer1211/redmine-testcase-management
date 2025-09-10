module TestCasesHelper
  include ApplicationsHelper

  def test_case_destroy_confirmation_message(test_case)
    message = "#{test_case.name}\n"
    message << l(:text_test_case_destroy_confirmation)
    message
  end

  def breadcrumb
    links = []

    if @test_plan_given
      links << link_to(l(:label_test_plans),
                       project_test_plans_path)
      links << "&#187;"
      if @test_plan
        links << link_to("##{@test_plan.id} #{@test_plan.name}",
                         project_test_plan_path(id: @test_plan.id))
        links << "&#187;"
      end
      links << ""
    elsif params[:action] != "index"
      links << link_to(l(:label_test_cases),
                       project_test_cases_path)
      links << "&#187;"
      links << ""
    end

    links.join(" ").html_safe
  end
end

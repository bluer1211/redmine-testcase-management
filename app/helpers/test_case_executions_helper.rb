module TestCaseExecutionsHelper
  include ApplicationsHelper

  def test_case_destroy_confirmation_message(test_case_execution)
    message = "#{test_case_execution.test_case.name}\n"
    message << l(:text_test_case_execution_destroy_confirmation)
    message
  end

  def breadcrumb
    links = []

    if @test_plan_given
      links << link_to(l(:label_test_plans),
                       project_test_plans_path)
      links << "&gt;\n"
      if @test_plan
        links << link_to("##{@test_plan.id} #{@test_plan.name}",
                         project_test_plan_path(id: @test_plan.id))
        links << "&gt;\n"
        if @test_case_given and @test_case
          links << link_to("#{l(:label_test_cases)} ##{@test_case.id} #{@test_case.name}",
                           project_test_plan_test_case_path(test_plan_id: @test_plan.id,
                                                            test_case_id: @test_case.id,
                                                            id: @test_plan.id))
          links << "&gt;\n"
        end
      end
    elsif @test_case_given
      links << link_to(l(:label_test_cases),
                       project_test_cases_path)
      links << "&gt;\n"
      if @test_case
        links << link_to("##{@test_case.id} #{@test_case.name}",
                         project_test_case_path(id: @test_case.id))
        links << "&gt;\n"
      end
    end

    links.join("\n").html_safe
  end
end

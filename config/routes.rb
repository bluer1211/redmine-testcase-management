# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do |map|
  resources :projects do
    resources :test_cases

    resources :test_plans do
      resources :test_cases do
        resources :test_case_executions
      end

      post 'assign_test_case', to: 'test_plans#assign_test_case'
      delete 'assign_test_case/:test_case_id', to: 'test_plans#unassign_test_case'
    end
  end
end

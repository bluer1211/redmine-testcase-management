# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do |map|
  resources :projects do
    get 'test_cases/auto_complete', to: 'test_cases#auto_completes', as: 'auto_complete_test_cases'

    resources :test_cases do
      resources :test_case_executions
    end

    resources :test_plans do
      resources :test_cases do
        resources :test_case_executions
      end

      resources :test_case_executions

      post 'assign_test_case', to: 'test_plans#assign_test_case'
      delete 'assign_test_case/:test_case_id', to: 'test_plans#unassign_test_case'
    end

    resources :test_case_executions
  end
end

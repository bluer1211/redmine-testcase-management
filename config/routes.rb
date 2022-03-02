# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do |map|
  resources :projects do
    resources :test_plans do
      resources :test_cases do
        resources :test_case_executions
      end
    end
  end
end

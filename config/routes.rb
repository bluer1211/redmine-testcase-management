# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do |map|
  resources :projects do
    get 'test_cases/auto_complete', to: 'test_cases#auto_complete', as: 'auto_complete_test_cases'

    get 'test_plans/statistics', to: 'test_plans#statistics', as: 'test_plan_statistics'
    get 'test_cases/statistics', to: 'test_cases#statistics', as: 'test_case_statistics'

    resources :test_cases do
      resources :test_case_executions
      collection do
        get 'bulk_edit'
        post 'bulk_update'
      end
    end

    match 'test_plans/context_menu', :to => 'test_plans#list_context_menu', :as => :test_plan_list_context_menu, :via => [:get, :post]
    resources :test_plans do
      resources :test_cases do
        resources :test_case_executions
      end

      resources :test_case_executions

      post 'assign_test_case', to: 'test_plans#assign_test_case'
      delete 'assign_test_case/:test_case_id', to: 'test_plans#unassign_test_case'
      delete 'assign_test_case', to: 'test_plans#unassign_test_case'

      match 'context_menu', :to => 'test_plans#show_context_menu', :as => :show_context_menu, :via => [:get, :post]
      collection do
        get 'bulk_edit'
        post 'bulk_update'
      end
    end

    resources :test_case_executions
  end

  get 'projects/:project_id/test_cases/imports/new',
      :to => 'imports#new',
      :defaults => {:type => 'TestCaseImport'},
      :as => 'new_test_cases_import'

  get 'projects/:project_id/test_plans/imports/new',
      :to => 'imports#new',
      :defaults => {:type => 'TestPlanImport'},
      :as => 'new_test_plans_import'

  get 'projects/:project_id/test_case_executions/imports/new',
      :to => 'imports#new',
      :defaults => {:type => 'TestCaseExecutionImport'},
      :as => 'new_test_case_executions_import'
end

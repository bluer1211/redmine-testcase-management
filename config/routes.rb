# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do |map|
  resources :projects do
    get 'test_cases/auto_complete', to: 'test_cases#auto_complete', as: 'auto_complete_test_cases'

    get 'test_plans/statistics', to: 'test_plans#statistics', as: 'test_plan_statistics'
    get 'test_cases/statistics', to: 'test_cases#statistics', as: 'test_case_statistics'

    match 'test_cases/context_menu', :to => 'test_cases#list_context_menu', :as => :test_case_list_context_menu, :via => [:get, :post]
    resources :test_cases do
      resources :test_case_executions
      collection do
        get 'bulk_edit'
        post 'bulk_update'
        delete 'bulk_delete'
      end
      #match 'context_menu', :to => 'test_cases#show_context_menu', :as => :show_context_menu, :via => [:get, :post]
    end

    match 'test_plans/context_menu', :to => 'test_plans#list_context_menu', :as => :test_plan_list_context_menu, :via => [:get, :post]
    resources :test_plans do
      resources :test_cases do
        resources :test_case_executions
      end

      resources :test_case_executions

      post 'assign_test_case', to: 'test_plans#assign_test_case'
      delete 'assign_test_case/:id', to: 'test_plans#unassign_test_case'
      delete 'assign_test_case', to: 'test_plans#unassign_test_case'

      match 'context_menu', :to => 'test_plans#show_context_menu', :as => :show_context_menu, :via => [:get, :post]
      collection do
        get 'bulk_edit'
        post 'bulk_update'
        delete 'bulk_delete'
      end
    end

    match 'test_case_executions/context_menu', :to => 'test_case_executions#list_context_menu', :as => :test_case_execution_list_context_menu, :via => [:get, :post]
    resources :test_case_executions do
      collection do
        get 'bulk_edit'
        post 'bulk_update'
        delete 'bulk_delete'
      end
    end
    
    # 使用自定義的匯入控制器
    resources :test_case_imports, :only => [:new, :create]
    resources :test_plan_imports, :only => [:new, :create]
    resources :test_case_execution_imports, :only => [:new, :create]
  end

  # 測試案例匯入的完整流程路由
  get 'projects/:project_id/test_cases/imports/new',
      :to => 'test_case_imports#new',
      :as => 'new_test_cases_import'
      
  post 'projects/:project_id/test_cases/imports',
      :to => 'test_case_imports#create',
      :as => 'test_case_imports'

  # 測試計劃匯入的完整流程路由
  get 'projects/:project_id/test_plans/imports/new',
      :to => 'test_plan_imports#new',
      :as => 'new_test_plans_import'
      
  post 'projects/:project_id/test_plans/imports',
      :to => 'test_plan_imports#create',
      :as => 'test_plan_imports'

  # 測試執行匯入的完整流程路由
  get 'projects/:project_id/test_case_executions/imports/new',
      :to => 'test_case_execution_imports#new',
      :as => 'new_test_case_executions_import'
      
  post 'projects/:project_id/test_case_executions/imports',
      :to => 'test_case_execution_imports#create',
      :as => 'test_case_execution_imports'
end

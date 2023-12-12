OpenProject::Application.routes.draw do
  scope 'projects/:project_id', as: 'project' do
    resources :gantt, controller: 'gantt/gantt', only: [:index] do
      collection do
        # states managed by client-side routing on work_package#index
        get '(/*state)' => 'gantt/gantt#index', as: ''
        get '/create_new' => 'gantt/gantt#index', as: 'new_split'
      end
    end
  end

  resources :gantt, controller: 'gantt/gantt', only: [:index] do
    collection do
      # states managed by client-side routing on work_package#index
      get 'details/*state' => 'gantt/gantt#index', as: :details

      # states managed by client-side (angular) routing on work_package#show
      get '/' => 'gantt/gantt#index', as: 'index'
    end
  end
end

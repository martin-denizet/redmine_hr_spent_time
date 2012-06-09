ActionController::Routing::Routes.draw do |map|
  #  map.resources :positions

  map.connect 'hr_spent_time/', :controller => 'hr_spent_time', :action => 'index'
  map.connect 'hr_spent_time/:action', :controller => 'hr_spent_time'
end

require 'redmine'

RAILS_DEFAULT_LOGGER.info 'Starting Time report plugin for Redmine'

Redmine::Plugin.register :redmine_time_report do
  name 'Redmine Time Report plugin'
  author 'Martin Denizet'
  description ''
  version '0.1.0'
  url 'https://github.com/martin-denizet/redmine_hr'
  author_url 'https://github.com/martin-denizet'

  #Worktime
  project_module :worktime do
    
    permission :view_hr_spent_time_tab, {:hr_spent_time =>
        [:index,:show,:total,:edit_relay,:relay_total,:relay_total2,:popup_select_issue,:ajax_select_issue,:popup_select_issues,:ajax_select_issues,:ajax_insert_daily,:ajax_memo_edit,:ajax_relay_table]}
    #permission :edit_hr_spent_time_total, {}
    #permission :view_hr_spent_time_other_member, {}
  end


  menu :top_menu, :last, { :controller => 'hr_spent_time', :action => 'index'  },
    :if =>  Proc.new {
    User.current.allowed_to?({:controller => 'hr_spent_time', :action => 'index'},nil, :global => true)
  },
    :caption => :hr_spent_time

  #menu :account_menu, :hr_spent_time, {:controller => 'hr_spent_time', :action => 'index'}, :caption => :hr_spent_time
  #menu :project_menu, :hr_spent_time, {:controller => 'hr_spent_time', :action => 'show'}, :caption => :hr_spent_time


end

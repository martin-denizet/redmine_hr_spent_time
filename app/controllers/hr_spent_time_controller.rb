class HrSpentTimeController < ApplicationController
  unloadable
  #  before_filter :find_project, :authorize

  helper :custom_fields
  helper :issues

  include CustomFieldsHelper

  NO_ORDER = -1

  def index
    require_login || return
    @project = nil
    prepare_values
    issue_del
    hour_update
    make_pack
    update_daily_memo
    @custom_fields = TimeEntryCustomField.find(:all)
    @link_params.merge!(:action=>"index")
    render "show"
  end

  def show
    find_project
    prepare_values
    issue_del
    hour_update
    make_pack
    update_daily_memo
    @custom_fields = TimeEntryCustomField.find(:all)
    @link_params.merge!(:action=>"show")
  end

  def total
    find_project
    prepare_values
    add_issue_relay
    calc_total
    @link_params.merge!(:action=>"total")
  end

  def edit_relay
    find_project
    prepare_values
    add_issue_relay
    calc_total
    @link_params.merge!(:action=>"edit_relay")
  end

  def relay_total
    find_project
    prepare_values
    add_issue_relay
    calc_total
    @link_params.merge!(:action=>"relay_total")
  end

  def relay_total2
    find_project
    prepare_values
    add_issue_relay
    calc_total
    @link_params.merge!(:action=>"relay_total2")
  end

  def popup_select_issue # チケット選択ウィンドウの内容を返すアクション
    render(:layout=>false)
  end

  def ajax_select_issue # チケット選択ウィンドウにAjaxで挿入(Update)される内容を返すアクション
    render(:layout=>false)
  end

  def popup_select_issues # 複数チケット選択ウィンドウの内容を返すアクション
    render(:layout=>false)
  end

  def ajax_select_issues # 複数チケット選択ウィンドウにAjaxで挿入(Update)される内容を返すアクション
    render(:layout=>false)
  end

  def ajax_insert_daily # 日毎工数に挿入するAjaxアクション
    prepare_values
    #@custom_fields = TimeEntryCustomField.find(:all)
    uid = params[:user]
    add_issue_id = params[:add_issue]
    @count = params[:count]
    if @this_uid==@crnt_uid then
      add_issue = Issue.find_by_id(add_issue_id)
      if add_issue && add_issue.visible? then
        prj = add_issue.project
        if User.current.allowed_to?(:log_time, prj) then

          @activities = []
          prj.activities.each do |act|
            @activities.push([act.name, act.id])
          end

          @add_issue = add_issue

          unless StUserIssueMonth.exists?(["user_id=:u and issue_id=:i",{:u=>uid, :i=>add_issue_id}]) then
            # 既存のレコードが存在していなければ追加
            StUserIssueMonth.create(:user_id=>uid, :issue_id=>add_issue_id,
              :position=>StUserIssueMonth.count(:conditions=>["user_id=:u",{:u=>uid}])+1)
          end
        end
      end
    end

    render(:layout=>false)
  end

  def ajax_memo_edit # 日毎のメモ入力フォームを出力するAjaxアクション
    render(:layout=>false)
  end

  def ajax_relay_table
    find_project
    authorize
    prepare_values
    member_add_del_check
    add_issue_relay
    change_member_position
    change_issue_position
    change_project_position
    calc_total
    @link_params.merge!(:action=>"edit_relay")
    render(:layout=>false)
  end

  def popup_update_done_ratio # 進捗％更新ポップアップ
    issue_id = params[:issue_id]
    @issue = Issue.find_by_id(issue_id)
    if @issue.closed? || !@issue.visible? then
      next if !params.key?(:all)
      @issueHtml = "<del>"+@issue.to_s+"</del>"
    else
      @issueHtml = @issue.to_s
    end
    render(:layout=>false)
  end

  def ajax_update_done_ratio
    issue_id = params[:issue_id]
    done_ratio = params[:done_ratio]
    @issue = Issue.find_by_id(issue_id)
    if User.current.allowed_to?(:edit_issues, @issue.project) then
      @issue.init_journal(User.current)
      @issue.done_ratio = done_ratio
      @issue.save
    end
    render(:layout=>false)
  end

  private
  def find_project
    # Redmine Pluginとして必要らしいので@projectを設定
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def prepare_values
    # ************************************* 値の準備
    @crnt_uid = User.current.id
    @this_uid = (params.key?(:user) && User.current.allowed_to?(:view_hr_spent_time_other_member, @project)) ? params[:user].to_i : @crnt_uid

    @today = Date.today
    @this_year = params.key?(:year) ? params[:year].to_i : @today.year
    @this_month = params.key?(:month) ? params[:month].to_i : @today.month
    @this_day = params.key?(:day) ? params[:day].to_i : @today.day
    @this_date = Date.new(@this_year, @this_month, @this_day)
    @last_month = @this_date << 1
    @next_month = @this_date >> 1
    @month_str = sprintf("%04d-%02d", @this_year, @this_month)

    @restrict_project = (params.key?(:prj) && params[:prj].to_i > 0) ? params[:prj].to_i : false

    @first_date = Date.new(@this_year, @this_month, 1)
    @last_date = (@first_date >> 1) - 1

    #Edit
    @month_days = Hash.new
    (@first_date..@last_date).each do |date|
      is_holiday=false
      is_selected=(@this_date==date)

      styles_array=[]
      styles_array.push("wt_calendar-saturday") if date.wday==6
      styles_array.push("wt_calendar-sunday") if date.wday==0
      styles_array.push("wt_calendar-holiday") if is_holiday
      styles_array.push("wt_calendar-selected-day") if is_selected

      style=styles_array.join(" ")

      @month_days[date] = {:is_holiday=>is_holiday,:date=>date,:is_selected=>is_selected,:style=>style}
      #puts @month_days
      
    end

    @month_days = @month_days.sort
    #puts @month_days
    #end edit
    @month_names = l(:wt_month_names).split(',')
    @wday_name = l(:wt_week_day_names).split(',')
    #@wday_color = ["#faa", "#eee", "#eee", "#eee", "#eee", "#eee", "#aaf"]

    @link_params = {:controller=>"hr_spent_time", :id=>@project,
      :year=>@this_year, :month=>@this_month, :day=>@this_day,
      :user=>@this_uid, :prj=>@restrict_project}
  end

  def issue_del # チケット削除処理
    if params.key?("issue_del") then
      if params["issue_del"]=="closed" then # 終了チケット全削除の場合
        issues = Issue.find(:all,
          :joins=>"INNER JOIN st_user_issue_months ON st_user_issue_months.issue_id=issues.id",
          :conditions=>["st_user_issue_months.user_id=:u",{:u=>@this_uid}])
        issues.each do |issue|
          if issue.closed? then
            tgt = UserIssueMonth.find(:first,
              :conditions=>["user_id=:u and issue_id=:i",{:u=>@this_uid,:i=>issue.id}])
            tgt.destroy
          end
        end
        return
      end

      # チケット番号指定の削除の場合
      src = UserIssueMonth.find(:first, :conditions=>
          ["uid=:u and issue=:i",
          {:u=>@this_uid,:i=>params["issue_del"]}])
      if src && src.uid == @crnt_uid then
        tgts = UserIssueMonth.find(:all, :conditions=>
            ["uid=:u and position>:o",{:u=>src.uid, :o=>src.position}])
        tgts.each do |tgt|
          tgt.position -= 1; tgt.save# 当該チケット表示より後ろの全チケットの順位をアップ
        end
        src.destroy# 当該チケット表示を削除
      end
    end
  end

  def hour_update # *********************************** 工数更新要求の処理
    return if @this_uid != @crnt_uid

    @message ||= ""
    # 新規工数の登録
    if params["new_time_entry"] then
      params["new_time_entry"].each do |issue_id, valss|
        issue = Issue.find_by_id(issue_id)
        next if issue.nil?
        next if !issue.visible?
        next if !User.current.allowed_to?(:log_time, issue.project)
        valss.each do |count, vals|
          next if vals['hours'] == ""
          if !vals['activity_id'] then
            @message += '<div style="background:#faa;">Error: Issue'+issue_id+': No Activities!</div><br>'
            next
          end
          new_entry = TimeEntry.new(:project => issue.project, :issue => issue, :user => User.current, :spent_on => @this_date)
          new_entry.attributes = vals
          new_entry.save
          msg = hour_update_check_error(new_entry, issue.id)
          @message += '<div style="background:#faa;">'+msg+'</div><br>' if msg != ""
        end
      end
    end

    # Man-hour update of the existing
    if params["time_entry"] then
      params["time_entry"].each do |id, vals|
        tm = TimeEntry.find(id)
        if vals["hours"] == "" then
          # If you delete an item is the empty string is specified man-hour man-hour
          tm.destroy
        else
          tm.attributes = vals
          tm.save
          msg = hour_update_check_error(tm, tm.issue.id)
          @message += '<div style="background:#faa;">'+msg+'</div><br>' if msg != ""
        end
      end
    end
  end

  def hour_update_check_error(obj, issue_id)
    return "" if obj.errors.empty?
    p obj
    str = "ERROR:#"+issue_id.to_s+"<br>"
    obj.errors.each do |attr, msg|
      next if msg.nil?
      if attr == "base"
        str += msg
      else
        str += "&#171; " + l("field_#{attr}") + " &#187; " + msg + "<br>" unless attr == "custom_values"
      end
    end
    # retrieve custom values error messages
    if obj.errors[:custom_values] then
      obj.custom_values.each do |v|
        v.errors.each do |attr, msg|
          next if msg.nil?
          str += "&#171; " + v.custom_field.name + " &#187; " + msg + "<br>"
        end
      end
    end
    return str
  end

 
  def update_daily_memo # 日ごとメモの更新
    text = params["memo"] || return # メモ更新のpostがあるか？
    year = params["year"] || return
    month = params["month"] || return
    day = params["day"] || return
    user_id = params["user"] || return

    # ユーザと日付で既存のメモを検索
    date = Date.new(year.to_i,month.to_i,day.to_i)
    find = StDailyMemo.find(:all, :conditions=>["day=:d and user_id=:u",{:d=>date,:u=>user_id}])
    while find.size > 1 do # もし複数見つかったら
      (find.shift).destroy # 消しておく
    end

    if find.size != 0 then
      # 既存のメモがあれば
      record = find.shift
      record.description = text
      record.updated_on = Time.now
      record.save # 更新
    else
      # 既存のメモがなければ新規作成
      now = Time.now
      StDailyMemo.create(:user_id=>user_id,
        :day=>date,
        :created_on=>now,
        :updated_on=>now,
        :description=>text)
    end
  end

 

  def make_pack
    # 月間工数表のデータを作成
    @month_pack = {:ref_prjs=>{}, :position_prjs=>[],
      :total=>0, :total_by_day=>{},
      :count_prjs=>0, :count_issues=>0}

    # 日毎工数のデータを作成
    @day_pack = {:ref_prjs=>{}, :position_prjs=>[],
      :total=>0, :total_by_day=>{},
      :count_prjs=>0, :count_issues=>0}

    # チケット順の表示データを作成
    dsp_issues = Issue.find(:all, :joins=>"INNER JOIN st_user_issue_months ON st_user_issue_months.issue_id=issues.id",
      :select=>"issues.*, st_user_issue_months.position",
      :conditions=>["st_user_issue_months.user_id=:u",{:u=>@this_uid}],
      :order=>"st_user_issue_months.position")
    dsp_issues.each do |issue|
      month_prj_pack = make_pack_prj(@month_pack, issue.project)
      make_pack_issue(month_prj_pack, issue, issue.position)
      day_prj_pack = make_pack_prj(@day_pack, issue.project)
      make_pack_issue(day_prj_pack, issue, issue.position)
    end
    @issue_position_max = dsp_issues.length

    # 月内の工数を集計
    time_entries = TimeEntry.find(:all, :conditions =>
        ["user_id=:uid and spent_on>=:day1 and spent_on<=:day2",
        {:uid => @this_uid, :day1 => @first_date, :day2 => @last_date}])
    time_entries.each do |time_entry|
      # 表示項目に工数のプロジェクトがあるかチェック→なければ項目追加
      prj_pack = make_pack_prj(@month_pack, time_entry.project)

      # 表示項目に工数のチケットがあるかチェック→なければ項目追加
      issue_pack = make_pack_issue(prj_pack, time_entry.issue)

      issue_pack[:count_hours] += 1

      # 合計時間の計算
      work_time = time_entry.hours
      @month_pack[:total] += work_time
      prj_pack[:total] += work_time
      issue_pack[:total] += work_time
      
      # 日毎の合計時間の計算
      date = time_entry.spent_on
      @month_pack[:total_by_day][date] ||= 0
      @month_pack[:total_by_day][date] += work_time
      prj_pack[:total_by_day][date] ||= 0
      prj_pack[:total_by_day][date] += work_time
      issue_pack[:total_by_day][date] ||= 0
      issue_pack[:total_by_day][date] += work_time

      if date==@this_date then # 表示日の工数であれば項目追加
        # 表示項目に工数のプロジェクトがあるかチェック→なければ項目追加
        day_prj_pack = make_pack_prj(@day_pack, time_entry.project)

        # 表示項目に工数のチケットがあるかチェック→なければ項目追加
        day_issue_pack = make_pack_issue(day_prj_pack, time_entry.issue, NO_ORDER)

        day_issue_pack[:each_entries][time_entry.id] = time_entry # 工数エントリを追加
        day_issue_pack[:total] += work_time
        day_prj_pack[:total] += work_time
        @day_pack[:total] += work_time
      end
    end

    # この日のチケット作成を洗い出す
    next_date = @this_date+1
    t1 = Time.local(@this_date.year, @this_date.month, @this_date.day)
    t2 = Time.local(next_date.year, next_date.month, next_date.day)
    issues = Issue.find(:all, :conditions=>["author_id=:u and created_on>=:t1 and created_on<:t2",
        {:u=>@this_uid, :t1=>t1, :t2=>t2}])
    issues.each do |issue|
      prj_pack = make_pack_prj(@day_pack, issue.project)
      issue_pack = make_pack_issue(prj_pack, issue)
      issue_pack[:worked] = true;
    end
    # この日のチケット操作を洗い出す
    issues = Issue.find(:all, :joins=>"INNER JOIN journals ON journals.journalized_id=issues.id",
      :conditions=>["journals.journalized_type='Issue' and
                                       journals.user_id=:u and
                                       journals.created_on>=:t1 and
                                       journals.created_on<:t2",
        {:u=>@this_uid, :t1=>t1, :t2=>t2}])
    issues.each do |issue|
      prj_pack = make_pack_prj(@day_pack, issue.project)
      issue_pack = make_pack_issue(prj_pack, issue)
      issue_pack[:worked] = true;
    end

    # 月間工数表から工数が無かった項目の削除と項目数のカウント
    @month_pack[:count_issues] = 0
    @month_pack[:position_prjs].each do |prj_pack|
      prj_pack[:position_issues].each do |issue_pack|
        if issue_pack[:count_hours]==0 then
          prj_pack[:count_issues] -= 1
        end
      end

      if prj_pack[:count_issues]==0 then
        @month_pack[:count_prjs] -= 1
      else
        @month_pack[:count_issues] += prj_pack[:count_issues]
      end
    end
  end

  def make_pack_prj(pack, new_prj, position=NO_ORDER)
    # 表示項目に当該プロジェクトがあるかチェック→なければ項目追加
    unless pack[:ref_prjs].has_key?(new_prj.id) then
      prj_pack = {:position=>position, :prj=>new_prj,
        :total=>0, :total_by_day=>{},
        :ref_issues=>{}, :position_issues=>[], :count_issues=>0}
      pack[:ref_prjs][new_prj.id] = prj_pack
      pack[:position_prjs].push prj_pack
      pack[:count_prjs] += 1
    end
    pack[:ref_prjs][new_prj.id]
  end

  def make_pack_issue(prj_pack, new_issue, position=NO_ORDER)
    # 表示項目に当該チケットがあるかチェック→なければ項目追加
    unless prj_pack[:ref_issues].has_key?(new_issue.id) then
      issue_pack = {:position=>position, :issue=>new_issue,
        :total=>0, :total_by_day=>{},
        :count_hours=>0, :each_entries=>{}}
      prj_pack[:ref_issues][new_issue.id] = issue_pack
      prj_pack[:position_issues].push issue_pack
      prj_pack[:count_issues] += 1
    end
    prj_pack[:ref_issues][new_issue.id]
  end

end

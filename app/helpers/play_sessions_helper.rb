module PlaySessionsHelper
  # 行ごとに Person.all を引くと参加者の数だけクエリが増える。
  def people_for_select
    @people_for_select ||= Person.all.to_a
  end

  def play_session_schedule(session)
    schedules = session.session_schedules.select(&:scheduled_on?)
    return "日程未定" if schedules.empty?

    schedules.map { |schedule| play_session_schedule_time(schedule) }.join("、")
  end

  def play_session_schedule_time(schedule)
    return "日程未定" if schedule.scheduled_on.blank?

    date = l(schedule.scheduled_on, format: :with_weekday)
    schedule.started_at.present? ? "#{date} #{schedule.started_at.strftime("%H:%M")}" : date
  end

  def play_session_status_label(session)
    t("play_sessions.statuses.#{session.derived_status}")
  end

  def participation_role_label(participation)
    t("play_sessions.roles.#{participation.role}")
  end
end

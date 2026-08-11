module PlaySessionsHelper
  # 行ごとに Person.all を引くと参加者の数だけクエリが増える。
  def people_for_select
    @people_for_select ||= Person.all.to_a
  end

  def play_session_schedule(session)
    schedules = session.session_schedules.filter_map(&:started_at)
    return "日程未定" if schedules.empty?

    schedules.map { |started_at| l(started_at, format: :session_schedule) }.join("、")
  end

  def play_session_status_label(session)
    t("play_sessions.statuses.#{session.derived_status}")
  end

  def participation_role_label(participation)
    t("play_sessions.roles.#{participation.role}")
  end
end

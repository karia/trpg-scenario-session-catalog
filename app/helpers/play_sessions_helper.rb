module PlaySessionsHelper
  def play_session_schedule(session)
    return "日程未定" if session.played_on.blank?

    date = l(session.played_on, format: :long)
    session.started_at.present? ? "#{date} #{l(session.started_at, format: :short)}" : date
  end

  def play_session_status_label(session)
    t("play_sessions.statuses.#{session.status}")
  end

  def participation_role_label(participation)
    t("play_sessions.roles.#{participation.role}")
  end
end

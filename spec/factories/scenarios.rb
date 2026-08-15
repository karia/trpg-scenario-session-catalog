FactoryBot.define do
  factory :game_system do
    sequence(:name) { |n| "システム#{n}" }
  end

  factory :author do
    sequence(:name) { |n| "作者#{n}" }
  end

  factory :scenario do
    sequence(:title) { |n| "シナリオ#{n}" }
    player_count_min { 1 }
  end

  factory :scenario_status do
    scenario
    person
    gm_experienced { false }
    pl_experienced { false }
    read { false }
  end

  factory :purchase_link do
    scenario
    label { "BOOTH" }
    url { "https://booth.pm/ja/items/1" }
  end

  factory :stream_link do
    scenario
    label { "配信" }
    url { "https://youtu.be/abc" }
  end
end

FactoryBot.define do
  factory :person do
    sequence(:display_name) { |n| "人物#{n}" }
  end

  factory :group do
    sequence(:name) { |n| "グループ#{n}" }
  end

  factory :user do
    sequence(:google_uid) { |n| "uid-#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
  end
end

FactoryBot.define do
  factory :play_session do
    scenario
  end

  factory :session_schedule do
    play_session
    scheduled_on { Date.new(2026, 5, 1) }
    started_at { "20:00" }
  end

  factory :recording_link do
    session_schedule
    sequence(:url) { |n| "https://youtu.be/recording#{n}" }
  end

  factory :participation do
    play_session
    person
    role { :player }
  end
end

FactoryBot.define do
  factory :person_alias do
    person
    sequence(:name) { |n| "別名#{n}" }
  end

  factory :favorite do
    person
    scenario
  end

  factory :spoiler_reveal do
    person
    scenario
  end
end

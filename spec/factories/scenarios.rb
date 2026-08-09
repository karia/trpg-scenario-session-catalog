FactoryBot.define do
  factory :game_system do
    sequence(:name) { |n| "システム#{n}" }
  end

  factory :author do
    sequence(:name) { |n| "作者#{n}" }
  end

  factory :scenario do
    sequence(:title) { |n| "シナリオ#{n}" }
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

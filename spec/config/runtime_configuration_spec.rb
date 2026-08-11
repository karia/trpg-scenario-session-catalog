require "rails_helper"

RSpec.describe "runtime configuration" do
  around do |example|
    original_values = ENV.values_at("DB_POOL", "JOB_THREADS")
    ENV["DB_POOL"] = "7"
    ENV["JOB_THREADS"] = "2"
    example.run
  ensure
    ENV["DB_POOL"], ENV["JOB_THREADS"] = original_values
  end

  it "configures the database pool independently from Puma threads" do
    configuration = ActiveRecord::DatabaseConfigurations.new(
      YAML.safe_load(ERB.new(Rails.root.join("config/database.yml").read).result, aliases: true)
    )

    expect(configuration.configs_for(env_name: "production", name: "primary").max_connections).to eq(7)
  end

  it "configures Solid Queue worker threads independently from worker processes" do
    configuration = YAML.safe_load(
      ERB.new(Rails.root.join("config/queue.yml").read).result,
      aliases: true
    )

    expect(configuration.dig("production", "workers", 0, "threads")).to eq(2)
  end
end

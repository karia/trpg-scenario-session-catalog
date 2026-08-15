# 最初の管理者は管理画面からは作れないため、ここで作る。
namespace :admin do
  desc "Link an OAuth account to a person and grant the admin role (PROVIDER=, UID= or EMAIL=, NAME=)"
  task grant: :environment do
    user = find_user
    person = user.person || Person.create!(display_name: ENV.fetch("NAME", user.email.to_s.split("@").first))
    user.update!(person:)
    person.person_roles.find_or_create_by!(name: "admin")

    puts "#{user.provider}:#{user.uid} (#{user.email}) -> #{person.display_name} (#{person.roles.join(", ")})"
  end

  # email は一意ではないため、複数該当したら選ばずに止める。
  def find_user
    if (uid = ENV["UID"]).present?
      provider = ENV.fetch("PROVIDER", "google_oauth2")
      User.find_by(provider:, uid:) or abort("No #{provider} user with UID #{uid}")
    elsif (email = ENV["EMAIL"]).present?
      users = User.where(email:).to_a
      abort("No user has signed in with #{email} yet") if users.empty?
      abort("#{users.size} users share #{email}; pass UID= instead") if users.size > 1
      users.first
    else
      abort("Pass UID= or EMAIL=")
    end
  end
end

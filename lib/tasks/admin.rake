# 最初の管理者は管理画面からは作れないため、ここで作る。
namespace :admin do
  desc "Link a Google account to a person and grant the admin role (EMAIL=, NAME=)"
  task grant: :environment do
    email = ENV.fetch("EMAIL")
    name = ENV.fetch("NAME", email.split("@").first)

    user = User.find_by(email:) or abort("No user has signed in with #{email} yet")
    person = user.person || Person.create!(display_name: name)
    user.update!(person:)
    person.person_roles.find_or_create_by!(name: "admin")

    puts "#{email} -> #{person.display_name} (#{person.roles.join(", ")})"
  end
end

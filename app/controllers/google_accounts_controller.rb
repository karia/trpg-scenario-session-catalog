class GoogleAccountsController < ApplicationController
  def create
    person = authorize current_person, :link?, policy_class: GoogleAccountPolicy
    User.link_google(request.env.fetch("omniauth.auth"), person)
    redirect_to person_path(person), notice: "Googleを連携しました"
  rescue KeyError, ArgumentError, ActiveRecord::ActiveRecordError
    redirect_to person_path(current_person), alert: "Googleを連携できませんでした"
  end

  def destroy
    person = policy_scope(Person).find(params[:person_id])
    authorize person, :unlink?, policy_class: GoogleAccountPolicy
    person.users.find_by!(provider: "google_oauth2").unlink_google!
    redirect_to person_path(person), notice: "Google連携を解除しました"
  end
end

class PeopleController < ApplicationController
  before_action :set_person, only: %i[show edit update destroy]

  def index
    authorize Person
    @people = policy_scope(Person).includes(:aliases, :groups, :person_roles, :users).with_attached_icon
  end

  def show
    authorize @person
  end

  def edit
    authorize @person, :update?
    prepare_discord_members
  end

  def update
    authorize @person, :update?

    @lost_roles = roles_lost_by_role_change
    return render_role_change_warning if @lost_roles.any?

    if @person.update(person_params)
      redirect_to person_path(@person), notice: "プロフィールを更新しました"
    else
      prepare_discord_members
      render :edit, status: :unprocessable_content
    end
  end

  def new
    @person = authorize Person.new, :create?
  end

  def create
    @person = authorize Person.new(admin_person_params), :create?
    return redirect_to(@person, notice: "#{@person.display_name} を登録しました") if @person.save
    render :new, status: :unprocessable_content
  end

  def destroy
    authorize @person, :destroy?
    return redirect_to(people_path, notice: "#{@person.display_name} を削除しました") if @person.destroy
    redirect_to people_path, alert: @person.errors.full_messages.join("、")
  end

  private
    def set_person
      @person = policy_scope(Person).find(params[:id])
    end

    def roles_lost_by_role_change
      return [] unless @person == current_person

      submitted = person_params[:roles]
      submitted.nil? ? [] : roles_lost_by(submitted)
    end

    # roles と manual_group_ids は代入した時点で DB に書かれる。確認前なので触らない。
    def render_role_change_warning
      @selected_roles = Array(person_params[:roles]).compact_blank
      @selected_group_ids = Array(person_params[:manual_group_ids]).compact_blank.map(&:to_i)
      @person.assign_attributes(person_params.except(:roles, :manual_group_ids))
      prepare_discord_members
      render :edit, status: :unprocessable_content
    end

    # グループ所属はここでは受け取らない。管理画面（管理者のみ）で扱う。
    def person_params
      permitted = [ :display_name, :display_alias_key, :x_account, :icon,
        { aliases_attributes: [ [ :id, :name, :context, :visible, :position, :selection_key, :_destroy ] ],
          person_aliases_attributes: [ [ :id, :name, :context, :visible, :position, :_destroy ] ] } ]
      permitted.prepend(:discord_uid) if policy(@person).manage?
      permitted << { roles: [], manual_group_ids: [] } if policy(@person).manage?
      params.expect(person: permitted)
    end

    def prepare_discord_members
      return unless policy(@person).manage?

      guild_ids = @person.groups.where.not(discord_guild_id: nil).unscope(:order).pluck(:discord_guild_id).uniq
      return if guild_ids.empty?

      client = DiscordGuildMemberClient.new
      members = guild_ids.flat_map { |guild_id| client.guild_members(guild_id) }.uniq { |member| member.fetch("id") }
      unavailable_uids = Person.where.not(id: @person.id).where.not(discord_uid: nil).pluck(:discord_uid)
      unavailable_uids.concat(User.where(provider: "discord").pluck(:uid))
      members.reject! { |member| unavailable_uids.include?(member.fetch("id")) && member.fetch("id") != @person.discord_uid }
      @discord_member_options = members.sort_by { |member| member.fetch("display_name").downcase }.map do |member|
        display_name = member.fetch("display_name")
        username = member.fetch("username")
        label = display_name == username ? display_name : "#{display_name} (@#{username})"
        [ label, member.fetch("id") ]
      end
      if @person.discord_uid.present? && @discord_member_options.none? { |_label, uid| uid == @person.discord_uid }
        @discord_member_options.unshift([ "現在のDiscordアカウント", @person.discord_uid ])
      end
    rescue DiscordGuildMemberClient::GuildMembersPermissionError
      @discord_members_error = "Discordの参加者一覧を取得するにはGUILD_MEMBERS privileged intentが必要です。"
    rescue DiscordGuildMemberClient::Error
      @discord_members_error = "Discordの参加者一覧を取得できませんでした。時間をおいて再度お試しください。"
    end

    def admin_person_params
      params.expect(person: [ :display_name, :x_account, :icon, { roles: [], manual_group_ids: [] } ])
    end
end

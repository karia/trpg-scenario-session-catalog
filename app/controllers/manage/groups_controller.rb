module Manage
  class GroupsController < MastersController
    private
      def model_class = Group

      def record_params
        params.expect(group: [ :name, :discord_guild_id, { person_ids: [] } ])
      end
  end
end

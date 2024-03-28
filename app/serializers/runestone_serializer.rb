# frozen_string_literal: true

class RunestoneSerializer < RealmLocationSerializer
  attributes :id, :name, :text, :discovered

  def discovered
    user = instance_options[:user]
    user.discovered_runestone? object.runestone_id
  end
end

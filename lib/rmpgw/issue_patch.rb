# RMP Group Watchers plugin
# Copyright (C) 2015 Kovalevsky Vasil (RMPlus company)
# Developed by Kovalevsky Vasil by order of "vira realtime"�http://rlt.ru/

module Rmpgw
  module IssuePatch
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do
        alias_method_chain :addable_watcher_users, :rmpgw
        alias_method_chain :watcher_user_ids=, :rmpgw
      end
    end

    module InstanceMethods
      def addable_watcher_users_with_rmpgw
        users = addable_watcher_users_without_rmpgw

        group_members_id = project.memberships.joins(:principal)
                            .where(:users => {:type => 'Group', :status => Principal::STATUS_ACTIVE})
                            .select(:user_id)

        Group.where(id: group_members_id).sorted.limit(100).to_a + users
      end

      def watcher_user_ids_with_rmpgw=(user_ids)
        if user_ids.is_a?(Array) && !user_ids.blank?
          user_ids_uniq = user_ids.uniq
          user_ids = User.joins("LEFT JOIN groups_users on groups_users.user_id = #{User.table_name}.id")
                         .active
                         .where("#{User.table_name}.id in (:user_ids)", user_ids: user_ids_uniq)
                         .uniq
                         .pluck(:id)
          user_ids = user_ids | User.joins("LEFT JOIN groups_users on groups_users.user_id = #{User.table_name}.id")
                         .active
                         .where("groups_users.group_id in (:user_ids)", user_ids: user_ids_uniq - user_ids)
                         .uniq
                         .pluck(:id)
        end

        send :watcher_user_ids_without_rmpgw=, user_ids
      end
    end
  end
end

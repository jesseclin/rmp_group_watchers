# RMP Group Watchers plugin
# Copyright (C) 2015 Kovalevsky Vasil (RMPlus company)
# Developed by Kovalevsky Vasil by order of "vira realtime"�http://rlt.ru/

module Rmpgw
  module IssuesControllerPatch
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do
        alias_method_chain :build_new_issue_from_params, :rmpgw
      end
    end

    module InstanceMethods
      def build_new_issue_from_params_with_rmpgw
        build_new_issue_from_params_without_rmpgw
        group_members_id = @project.memberships.joins(:principal)
                            .where(:users => {:type => 'Group', :status => Principal::STATUS_ACTIVE})
                            .select(:user_id)
        @available_watchers = Group.where(id: group_members_id).sorted.to_a + (@available_watchers || [])
      end
    end
  end
end

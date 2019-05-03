# RMP Group Watchers plugin
# Copyright (C) 2015 Kovalevsky Vasil (RMPlus company)
# Developed by Kovalevsky Vasil by order of "vira realtime" http://rlt.ru/

module Rmpgw
  module WatchersControllerPatch
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do
        alias_method_chain :autocomplete_for_user, :rmpgw
        alias_method_chain :append, :rmpgw
        alias_method_chain :create, :rmpgw
      end
    end

    module InstanceMethods
      def autocomplete_for_user_with_rmpgw
         scope = nil
         if @project.present?
            scope = @project.users
         else 
            scope = User.all.limit(100)
         end
         users = scope.active.visible.sorted.like(params[:q]).to_a
         if @project.present?
            scope = Group.where(id: @project.memberships.joins(:principal)
                                            .where(:users => {:type => 'Group', :status => Principal::STATUS_ACTIVE}).select(:user_id))
         else 
            scope = Group.all.limit(100)
         end
         groups = scope.active.visible.order(:lastname).where(type: 'Group').like(params[:q]).limit(100).to_a

        if params[:object_type].blank? || params[:object_type] == 'issue'
          @users = groups + users
          if @watchables.present?
            @users -= @watchables.first.watcher_users
          end
          render layout: false
        else
          autocomplete_for_user_without_rmpgw
        end
      end

      def append_with_rmpgw
        if params[:watcher].is_a?(Hash)
          user_ids = params[:watcher][:user_ids] || [params[:watcher][:user_id]] || []
          groups = User.joins("LEFT JOIN groups_users on groups_users.user_id = #{User.table_name}.id").active
              .where("groups_users.group_id in (:user_ids)", user_ids: user_ids + [0])
          users = User.joins("LEFT JOIN groups_users on groups_users.user_id = #{User.table_name}.id").active
              .where("#{User.table_name}.id in (:user_ids)", user_ids: user_ids + [0])
          @users = (groups + users).uniq.sort
        end
      end

      def create_with_rmpgw
        logger.debug "TEST"
        if @watchables.first.class.name.underscore == 'issue'
          if params[:watcher].is_a?(Hash)
            user_ids = (params[:watcher][:user_ids] || params[:watcher][:user_id])
          else
            user_ids = params[:user_id]
          end
          params[:watcher] = {}
          unless user_ids.nil?
            groups = User.joins("LEFT JOIN groups_users on groups_users.user_id = #{User.table_name}.id").active
                         .where("groups_users.group_id in (:user_ids)", user_ids: user_ids + [0])
            users = User.joins("LEFT JOIN groups_users on groups_users.user_id = #{User.table_name}.id").active
                         .where("#{User.table_name}.id in (:user_ids)", user_ids: user_ids + [0])
            params[:watcher][:user_id] = (groups + users).uniq.sort.map(&:id)
          end
        end

        create_without_rmpgw
      end
    end
  end
end

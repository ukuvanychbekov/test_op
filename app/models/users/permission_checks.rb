#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Users::PermissionChecks
  extend ActiveSupport::Concern

  included do
    delegate :preload_projects_allowed_to, to: :user_allowed_service

    # Some Ruby magic. Create methods for each entity we can have memberships on automatically
    # i.e. allowed_in_work_package? and allowed_in_any_work_package?
    Member::ALLOWED_ENTITIES.each do |entity_model_name|
      entity_name_underscored = entity_model_name.underscore
      entity_class = entity_model_name.constantize

      define_method "allowed_in_#{entity_name_underscored}?" do |permission, entity|
        allowed_in_entity?(permission, entity, entity_class)
      end

      define_method "allowed_in_any_#{entity_name_underscored}?" do |permission, in_project: nil|
        allowed_in_any_entity?(permission, entity_class, in_project:)
      end
    end
  end

  class_methods do
    def allowed(action, project)
      Authorization.users(action, project)
    end

    def allowed_members(action, project)
      Authorization.users(action, project).where.not(members: { id: nil })
    end

    def allowed_members_on_work_package(action, work_package)
      project_members = allowed_members(action, work_package.project)
                          .where(members: { entity: nil })
      work_package_members = allowed_members(action, work_package.project)
                               .where(members: { entity: work_package })

      project_members.or(work_package_members)
    end
  end

  def reload(*args)
    @user_permissible_service = nil
    @user_allowed_service = nil
    @project_role_cache = nil

    super
  end

  # All the new methods to check for permissions. This will completely replace the old interface:
  delegate :allowed_globally?,
           :allowed_in_project?,
           :allowed_in_any_project?,
           :allowed_in_entity?,
           :allowed_in_any_entity?,
           to: :user_permissible_service

  # Return user's roles for project
  def roles_for_project(project)
    project_role_cache.fetch(project)
  end
  alias :roles :roles_for_project

  # Return user's role for the work package.
  # Which consists of both the roles granted to the user directly on the work package
  # as well as those granted to the user on the project the work package belongs to.
  def roles_for_work_package(work_package)
    roles_for_project(work_package.project) +
      Role.includes(:member_roles)
          .where(member_roles: { member_id: Member.of_work_package(work_package).select(:id) })
  end

  # Return true if the user is a member of project
  def member_of?(project)
    roles_for_project(project).any?(&:member?)
  end

  def all_permissions_for(context)
    Authorization
      .roles(self, context)
      .includes(:role_permissions)
      .pluck(:permission)
      .compact
      .map(&:to_sym)
      .uniq
  end

  # Helper method to be used in places where we just throw anything into the permission check and don't know what
  # context it should be checked on. Things like menu item checks, controller action checks, generic services, etc.
  def allowed_based_on_permission_context?(permission, project: nil, entity: nil) # rubocop:disable Metrics/PerceivedComplexity, Metrics/AbcSize
    permissions = Authorization.permissions_for(permission, raise_on_unknown: true)

    entity_blank_or_not_project_scoped = entity.blank? || !entity.respond_to?(:project) || (entity.respond_to?(:project) && entity.project.blank?)
    entity_is_work_package_or_list = (entity.is_a?(WorkPackage) && entity.persisted?) || (entity.is_a?(Enumerable) && entity.all?(WorkPackage))
    entity_is_project_scoped_and_project_is_present = entity.respond_to?(:project) && entity.project.present?

    permissions.any? do |perm|
      if perm.global?
        allowed_globally?(perm)
      elsif perm.work_package? && entity_is_work_package_or_list
        allowed_in_work_package?(perm, entity)
      elsif perm.work_package? && entity.blank? && project.blank?
        allowed_in_any_work_package?(perm)
      elsif perm.work_package? && entity && entity.new_record? && entity.respond_to?(:project)
        allowed_in_any_work_package?(perm, in_project: entity.project)
      elsif perm.work_package? && project && (entity.blank? || entity.new_record?)
        allowed_in_any_work_package?(perm, in_project: project)
      elsif perm.project? && project
        allowed_in_project?(perm, project)
      elsif perm.project? && project.nil? && entity.present? && entity_is_project_scoped_and_project_is_present
        allowed_in_project?(perm, entity.project)
      elsif perm.project? && entity_blank_or_not_project_scoped && project.blank?
        allowed_in_any_project?(perm)
      else
        false
      end
    end
  end

  # Old allowed_to? interface. Marked as deprecated, should be removed at some point ... Guessing 14.0?
  def allowed_to?(action, context, global: false)
    OpenProject::Deprecation.deprecate_method(User, :allowed_to?)
    user_allowed_service.call(action, context, global:)
  end

  def allowed_to_in_project?(action, project)
    OpenProject::Deprecation.replaced(:allowed_to_in_project?, :allowed_in_project?, caller)
    allowed_to?(action, project)
  end

  def allowed_to_globally?(action)
    OpenProject::Deprecation.replaced(:allowed_to_globally?, :allowed_globally?, caller)
    allowed_to?(action, nil, global: true)
  end

  private

  def user_allowed_service
    @user_allowed_service ||= ::Authorization::UserAllowedService.new(self, role_cache: project_role_cache)
  end

  def user_permissible_service
    @user_permissible_service ||= ::Authorization::UserPermissibleService.new(self)
  end

  def project_role_cache
    @project_role_cache ||= ::Users::ProjectRoleCache.new(self)
  end
end

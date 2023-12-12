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

class ProjectsController < ApplicationController
  menu_item :overview
  menu_item :roadmap, only: :roadmap

  before_action :find_project, except: %i[index new]
  before_action :authorize, only: %i[copy]
  before_action :authorize_global, only: %i[new]
  before_action :require_admin, only: %i[destroy destroy_info]

  include SortHelper
  include PaginationHelper
  include QueriesHelper
  include ProjectsHelper

  helper_method :has_managed_project_folders?

  current_menu_item :index do
    :projects
  end

  def index
    query = load_query

    unless query.valid?
      flash[:error] = query.errors.full_messages
    end

    @projects = load_projects query
    @orders = set_sorting query

    respond_to do |format|
      format.html do
        render layout: 'global'
      end

      format.any(*supported_export_formats) do
        export_list(request.format.symbol)
      end
    end
  end

  def new
    render layout: 'no_menu'
  end

  def copy
    render
  end

  # Delete @project
  def destroy
    service_call = ::Projects::ScheduleDeletionService
                     .new(user: current_user, model: @project)
                     .call

    if service_call.success?
      flash[:notice] = I18n.t('projects.delete.scheduled')
    else
      flash[:error] = I18n.t('projects.delete.schedule_failed', errors: service_call.errors.full_messages.join("\n"))
    end

    redirect_to projects_path
  end

  def destroy_info
    @project_to_destroy = @project

    hide_project_in_layout
  end

  private

  def has_managed_project_folders?(project)
    project.project_storages.any?(&:project_folder_automatic?)
  end

  def find_optional_project
    return true unless params[:id]

    @project = Project.find(params[:id])
    authorize
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def hide_project_in_layout
    @project = nil
  end

  def load_query
    @query = ParamsToQueryService.new(Project, current_user).call(params)

    # Set default filter on status no filter is provided.
    @query.where('active', '=', OpenProject::Database::DB_VALUE_TRUE) unless params[:filters]

    # Order lft if no order is provided.
    @query.order(lft: :asc) unless params[:sortBy]

    @query
  end

  def export_list(mime_type)
    job = Projects::ExportJob.perform_later(
      export: Projects::Export.create,
      user: current_user,
      mime_type:,
      query: @query.to_hash
    )

    if request.headers['Accept']&.include?('application/json')
      render json: { job_id: job.job_id }
    else
      redirect_to job_status_path(job.job_id)
    end
  end

  def load_projects(query)
    query
      .results
      .with_required_storage
      .with_latest_activity
      .includes(:custom_values, :enabled_modules)
      .paginate(page: page_param, per_page: per_page_param)
  end

  def set_sorting(query)
    query.orders.select(&:valid?).map { |o| [o.attribute.to_s, o.direction.to_s] }
  end

  def supported_export_formats
    ::Exports::Register.list_formats(Project).map(&:to_s)
  end

  helper_method :supported_export_formats
end

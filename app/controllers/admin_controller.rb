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
require 'open3'

class AdminController < ApplicationController
  layout 'admin'

  before_action :require_admin, except: %i[index]
  before_action :authorize_global, only: %i[index]

  menu_item :plugins, only: [:plugins]
  menu_item :info, only: [:info]
  menu_item :admin_overview, only: [:index]

  def index
    @menu_nodes = Redmine::MenuManager.items(:admin_menu).children.reject do |node|
      name = node.name
      condition = node.condition

      name === :admin_overview ||
        (condition && !condition.call) ||
        hidden_admin_menu_items.include?(name.to_s)
    end

    if @menu_nodes.count == 1
      redirect_to @menu_nodes.first.url
    end
  end

  def projects
    redirect_to controller: 'projects', action: 'index'
  end

  def plugins
    @plugins = Redmine::Plugin.all.sort
  end

  def test_email
    raise_delivery_errors = ActionMailer::Base.raise_delivery_errors
    # Force ActionMailer to raise delivery errors so we can catch it
    ActionMailer::Base.raise_delivery_errors = true
    begin
      @test = UserMailer.test_mail(User.current).deliver_now
      flash[:notice] = I18n.t(:notice_email_sent, value: User.current.mail)
    rescue StandardError => e
      flash[:error] = I18n.t(:notice_email_error, value: Redmine::CodesetUtil.replace_invalid_utf8(e.message.dup))
    end
    ActionMailer::Base.raise_delivery_errors = raise_delivery_errors
    redirect_to admin_settings_mail_notifications_path
  end

  def info
    @db_version = OpenProject::Database.version
    @checklist = [
      [:text_default_administrator_account_changed, User.default_admin_account_changed?],
      [:text_database_allows_tsv, OpenProject::Database.allows_tsv?]
    ]

    @checklist += file_storage_checks
    @checklist += plaintext_extraction_checks
    @checklist += admin_information_hook_checks
    @checklist += image_conversion_checks

    @storage_information = OpenProject::Storage.mount_information
  end

  def default_breadcrumb
    case params[:action]
    when 'plugins'
      t(:label_plugins)
    when 'info'
      t(:label_information)
    end
  end

  def show_local_breadcrumb
    true
  end

  private

  def hidden_admin_menu_items
    (OpenProject::Configuration.hidden_menu_items[:admin_menu.to_s] || [])
  end

  def plaintext_extraction_checks
    if OpenProject::Database.allows_tsv?
      [
        [:'extraction.available.pdftotext', Plaintext::PdfHandler.available?],
        [:'extraction.available.unrtf', Plaintext::RtfHandler.available?],
        [:'extraction.available.catdoc', Plaintext::DocHandler.available?],
        [:'extraction.available.xls2csv', Plaintext::XlsHandler.available?],
        [:'extraction.available.catppt', Plaintext::PptHandler.available?],
        [:'extraction.available.tesseract', Plaintext::ImageHandler.available?]
      ]
    else
      []
    end
  end

  def image_conversion_checks
    [[:'image_conversion.imagemagick', image_conversion_libs_available?]]
  end

  def image_conversion_libs_available?
    Open3.capture2e('convert', '-version').first.include?('ImageMagick')
  rescue StandardError
    false
  end

  def file_storage_checks
    # Add local directory test if we're not using fog
    if OpenProject::Configuration.file_storage?
      repository_writable = File.writable?(OpenProject::Configuration.attachments_storage_path)
      [[:text_file_repository_writable, repository_writable]]
    else
      []
    end
  end

  def admin_information_hook_checks
    call_hook(:admin_information_checklist).flat_map do |result|
      result
    end
  end
end

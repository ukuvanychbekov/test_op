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

class Widget::Controls::Delete < Widget::Controls
  def render
    return '' if @subject.new_record? or !@options[:can_delete]

    button = link_to(I18n.t(:button_delete),
                     '#',
                     id: 'query-icon-delete',
                     class: 'button icon-context icon-delete')
    popup = content_tag :div, id: 'delete_form', style: 'display:none', class: 'button_form' do
      question = content_tag :p, I18n.t(:label_really_delete_question)

      url_opts = { id: @subject.id }
      url_opts[request_forgery_protection_token] = form_authenticity_token # if protect_against_forgery?
      opt1 = link_to I18n.t(:button_delete),
                     url_for(url_opts),
                     method: :delete,
                     class: 'button -highlight icon-context icon-delete'
      opt2 = link_to I18n.t(:button_cancel),
                     '#',
                     id: 'query-icon-delete-cancel',
                     class: 'button icon-context icon-cancel'
      opt1 + opt2

      question + opt1 + opt2
    end
    write(button + popup)
  end
end

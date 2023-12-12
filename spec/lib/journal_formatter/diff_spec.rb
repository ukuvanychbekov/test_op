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

require 'spec_helper'

RSpec.describe OpenProject::JournalFormatter::Diff do
  include ActionView::Helpers::TagHelper
  # WARNING: the order of the modules is important to ensure that url_for of
  # ActionController::UrlWriter is called and not the one of ActionView::Helpers::UrlHelper
  include ActionView::Helpers::UrlHelper

  def url_helper
    Rails.application.routes.url_helpers
  end

  let(:klass) { described_class }
  let(:id) { 1 }
  let(:work_package) do
    build_stubbed(:work_package,
                  subject: 'Test subject',
                  status_id: 1,
                  type_id: 1,
                  project_id: 1)
  end
  let(:journal) do
    build_stubbed(:work_package_journal,
                  journable: work_package,
                  created_at: 3.days.ago.to_date,
                  version: 1,
                  data: build(:journal_work_package_journal,
                              subject: work_package.subject,
                              status_id: work_package.status_id,
                              type_id: work_package.type_id,
                              project_id: work_package.project_id))
  end
  let(:instance) { klass.new(journal) }
  let(:key) { 'description' }

  let(:path) do
    url_helper.diff_journal_path(id: journal.id,
                                 field: key.downcase)
  end
  let(:url) do
    url_helper.diff_journal_url(id: journal.id,
                                field: key.downcase,
                                protocol: Setting.protocol,
                                host: Setting.host_name)
  end
  let(:link) { link_to(I18n.t(:label_details), path, class: 'description-details') }
  let(:full_url_link) { link_to(I18n.t(:label_details), url, class: 'description-details') }

  describe '#render' do
    describe 'WITH the first value being nil, and the second a string' do
      let(:expected) do
        I18n.t(:text_journal_set_with_diff,
               label: "<strong>#{key.camelize}</strong>",
               link:)
      end

      it { expect(instance.render(key, [nil, 'new value'])).to eq(expected) }
    end

    describe 'WITH the first value being a string, and the second a string' do
      let(:expected) do
        I18n.t(:text_journal_changed_with_diff,
               label: "<strong>#{key.camelize}</strong>",
               link:)
      end

      it { expect(instance.render(key, ['old value', 'new value'])).to eq(expected) }
    end

    describe "WITH the first value being a string, and the second a string
              WITH de as locale" do
      let(:expected) do
        I18n.t(:text_journal_changed_with_diff,
               label: '<strong>Beschreibung</strong>',
               link:)
      end

      before do
        I18n.locale = :de
      end

      after do
        I18n.locale = :en
      end

      it { expect(instance.render(key, ['old value', 'new value'])).to eq(expected) }
    end

    describe 'WITH the first value being a string, and the second nil (with link)' do
      let(:expected) do
        I18n.t(:text_journal_deleted_with_diff,
               label: "<strong>#{key.camelize}</strong>",
               link:)
      end

      it { expect(instance.render(key, ['old_value', nil])).to eq(expected) }
    end

    describe "WITH the first value being nil, and the second a string
              WITH specifying not to output html" do
      let(:expected) do
        I18n.t(:text_journal_set_with_diff,
               label: key.camelize,
               link: path)
      end

      it { expect(instance.render(key, [nil, 'new value'], html: false)).to eq(expected) }
    end

    describe "WITH the first value being a string, and the second a string
              WITH specifying not to output html" do
      let(:expected) do
        I18n.t(:text_journal_changed_with_diff,
               label: key.camelize,
               link: path)
      end

      it { expect(instance.render(key, ['old value', 'new value'], html: false)).to eq(expected) }
    end

    describe "WITH the first value being a string, and the second a string
              WITH specifying to output a full url" do
      let(:expected) do
        I18n.t(:text_journal_changed_with_diff,
               label: "<strong>#{key.camelize}</strong>",
               link: full_url_link)
      end

      it { expect(instance.render(key, ['old value', 'new value'], only_path: false)).to eq(expected) }
    end

    describe 'WITH the first value being a string, and the second nil (with url)' do
      let(:expected) do
        I18n.t(:text_journal_deleted_with_diff,
               label: key.camelize,
               link: path)
      end

      it { expect(instance.render(key, ['old_value', nil], html: false)).to eq(expected) }
    end
  end
end

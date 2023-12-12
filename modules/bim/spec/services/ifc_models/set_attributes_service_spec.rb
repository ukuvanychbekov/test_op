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

RSpec.describe Bim::IfcModels::SetAttributesService, type: :model do
  shared_let(:project) { create(:project, enabled_module_names: %i[bim]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %i[bim]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[manage_ifc_models] }) }

  let(:other_user) { build_stubbed(:user) }
  let(:contract_class) do
    contract = double('contract_class')

    allow(contract)
      .to receive(:new)
      .with(model, user, options: {})
      .and_return(contract_instance)

    contract
  end
  let(:contract_instance) do
    double('contract_instance', validate: contract_valid, errors: contract_errors)
  end
  let(:contract_valid) { true }
  let(:contract_errors) do
    double('contract_errors')
  end
  let(:model_valid) { true }
  let(:instance) do
    described_class.new(user:,
                        model:,
                        contract_class:)
  end
  let(:call_attributes) { {} }
  let(:ifc_file) { FileHelpers.mock_uploaded_file(name: "model_2.ifc", content_type: 'application/binary', binary: true) }
  let(:model) do
    create(:ifc_model, project:, uploader: other_user)
  end

  before do
    # required for the attachments
    login_as(user)
  end

  describe 'call' do
    let(:call_attributes) do
      {
        project_id: other_project.id
      }
    end

    before do
      allow(model)
        .to receive(:valid?)
        .and_return(model_valid)

      expect(contract_instance)
        .to receive(:validate)
        .and_return(contract_valid)
    end

    subject { instance.call(call_attributes) }

    it 'is successful' do
      expect(subject.success?).to be_truthy
    end

    it 'sets the attributes' do
      subject

      expect(model.attributes.slice(*model.changed).symbolize_keys)
        .to eql call_attributes.merge(uploader_id: user.id)
    end

    it 'does not persist the model' do
      expect(model)
        .not_to receive(:save)

      subject
    end

    context 'for a new record' do
      let(:model) do
        Bim::IfcModels::IfcModel.new project:
      end

      context 'with an ifc_attachment' do
        let(:call_attributes) do
          {
            ifc_attachment: ifc_file
          }
        end

        it 'is successful' do
          expect(subject.success?).to be_truthy
        end

        it 'sets the title to the attachment`s filename' do
          subject

          expect(model.title)
            .to eql 'model_2'
        end

        it 'sets the uploader to the attachment`s author (which is the current user)' do
          subject

          expect(model.uploader)
            .to eql user
        end
      end
    end

    context 'for an existing model' do
      context 'with an ifc_attachment' do
        let(:call_attributes) do
          {
            ifc_attachment: ifc_file
          }
        end

        it 'is successful' do
          expect(subject.success?).to be_truthy
        end

        it 'does not alter the title' do
          title_before = model.title

          subject

          expect(model.title)
            .to eql title_before
        end

        it 'sets the uploader to the attachment`s author (which is the current user)' do
          subject

          expect(model.uploader)
            .to eql user
        end

        it 'marks existing attachments for destruction' do
          ifc_attachment = model.ifc_attachment

          subject

          expect(ifc_attachment)
            .to be_marked_for_destruction
        end
      end
    end
  end
end

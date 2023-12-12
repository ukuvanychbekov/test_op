// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Transition } from '@uirouter/core';
import { Injectable } from '@angular/core';
import { EditFormRoutingService } from 'core-app/shared/components/fields/edit/edit-form/edit-form-routing.service';

@Injectable()
export class WorkPackageEditFormRoutingService extends EditFormRoutingService {
  /**
   * Return whether the given transition is cancelled during the editing of this form
   *
   * @param transition The transition that is underway.
   * @return A boolean marking whether the transition should be blocked.
   */
  public blockedTransition(transition:Transition):boolean {
    const toState = transition.to();
    const fromState = transition.from();
    const fromParams = transition.params('from');
    const toParams = transition.params('to');

    // In new/copy mode, transitions to the same controller are allowed
    if (fromState.name && (/\.(new|copy)$/.exec(fromState.name))) {
      return !(toState.data && toState.data.allowMovingInEditMode);
    }

    // When editing an existing WP, transitions on the same WP id are allowed
    return toParams.workPackageId === undefined || toParams.workPackageId !== fromParams.workPackageId;
  }
}

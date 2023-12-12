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

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  Input,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { WorkPackageShareModalComponent } from 'core-app/features/work-packages/components/wp-share-modal/wp-share.modal';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-share-button',
  templateUrl: './wp-share-button.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WorkPackageShareButtonComponent extends UntilDestroyedMixin {
  @Input() public workPackage:WorkPackageResource;

  public text = {
    share: this.I18n.t('js.work_packages.sharing.share'),
  };

  constructor(
    readonly I18n:I18nService,
    readonly opModalService:OpModalService,
    readonly cdRef:ChangeDetectorRef,
  ) {
    super();
  }

  openModal():void {
    this.opModalService.show(WorkPackageShareModalComponent, 'global', { workPackage: this.workPackage });
  }
}

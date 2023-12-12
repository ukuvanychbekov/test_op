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

import {
  ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Inject, OnInit,
} from '@angular/core';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HelpTextResource } from 'core-app/features/hal/resources/help-text-resource';

@Component({
  templateUrl: './help-text.modal.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AttributeHelpTextModalComponent extends OpModalComponent implements OnInit {
  readonly text = {
    attachments: this.I18n.t('js.label_attachments'),
    edit: this.I18n.t('js.button_edit'),
    close: this.I18n.t('js.button_close'),
  };

  public helpText:HelpTextResource = this.locals.helpText!;

  constructor(
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly I18n:I18nService,
    readonly cdRef:ChangeDetectorRef,
    readonly elementRef:ElementRef,
  ) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit() {
    super.ngOnInit();

    // Load the attachments
    this
      .helpText
      .attachments
      .$load()
      .then(() => this.cdRef.detectChanges());
  }

  public get helpTextLink() {
    if (this.helpText.editText) {
      return this.helpText.editText.$link.href;
    }

    return '';
  }
}

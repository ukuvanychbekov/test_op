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
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.

import { Injector, NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HookService } from 'core-app/features/plugins/hook-service';
import { AvatarUploadFormComponent } from './avatar-upload-form/avatar-upload-form.component';

@NgModule({
  imports: [
    CommonModule,
  ],
  declarations: [
    AvatarUploadFormComponent,
  ],
})
export class PluginModule {
  constructor(injector:Injector) {
    const hookService = injector.get(HookService);
    hookService.register('openProjectAngularBootstrap', () => [
      { selector: 'avatar-upload-form', cls: AvatarUploadFormComponent },
    ]);
  }
}

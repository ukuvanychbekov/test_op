/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { Controller } from '@hotwired/stimulus';
import {
  combineLatest,
  from,
  Observable,
  of,
} from 'rxjs';
import {
  filter,
  map,
  switchMap,
} from 'rxjs/operators';

import { IStorage } from 'core-app/core/state/storages/storage.model';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { IStorageFile } from 'core-app/core/state/storage-files/storage-file.model';
import { storageConnected } from 'core-app/shared/components/storages/storages-constants.const';
import {
  LocationPickerModalComponent,
} from 'core-app/shared/components/storages/location-picker-modal/location-picker-modal.component';

export default class ProjectStorageFormController extends Controller {
  static targets = [
    'projectFolderSection',
    'projectFolderIdInput',
    'projectFolderIdValidation',
    'selectedFolderText',
    'selectProjectFolderButton',
    'loginButton',
    'storage',
  ];

  static values = {
    folderMode: String,
    placeholderFolderName: String,
    notLoggedInValidation: String,
    lastProjectFolders: Object,
  };

  declare folderModeValue:string;

  declare placeholderFolderNameValue:string;

  declare notLoggedInValidationValue:string;

  declare lastProjectFoldersValue:{ manual:string; automatic:string };

  declare readonly storageTarget:HTMLElement;

  declare readonly selectProjectFolderButtonTarget:HTMLButtonElement;

  declare readonly loginButtonTarget:HTMLButtonElement;

  declare readonly projectFolderSectionTarget:HTMLElement;

  declare readonly projectFolderIdInputTarget:HTMLInputElement;

  declare readonly projectFolderIdValidationTarget:HTMLSpanElement;

  declare readonly hasProjectFolderIdValidationTarget:boolean;

  declare readonly selectedFolderTextTarget:HTMLSpanElement;

  declare readonly hasProjectFolderSectionTarget:boolean;

  connect():void {
    combineLatest([
      this.fetchStorageAuthorizationState(),
      this.fetchProjectFolder(),
    ]).subscribe(([isConnected, projectFolder]) => {
      if (isConnected) {
        this.selectProjectFolderButtonTarget.style.display = 'inline-block';
        this.loginButtonTarget.style.display = 'none';
        this.selectedFolderTextTarget.innerText = projectFolder === null
          ? this.placeholderFolderNameValue
          : projectFolder.name;
      } else {
        this.selectProjectFolderButtonTarget.style.display = 'none';
        this.loginButtonTarget.style.display = 'inline-block';
        this.selectedFolderTextTarget.innerText = this.notLoggedInValidationValue;
      }

      this.toggleFolderDisplay(this.folderModeValue);
    });
  }

  selectProjectFolder(_evt:Event):void {
    const locals = {
      projectFolderHref: this.projectFolderHref,
      storage: this.storage,
    };

    this.modalService
      .pipe(
        switchMap((service) => service.show(LocationPickerModalComponent, 'global', locals)),
        switchMap((modal) => modal.closingEvent),
        filter((modal) => modal.submitted),
      )
      .subscribe((modal) => {
        if (this.hasProjectFolderIdValidationTarget) {
          this.projectFolderIdValidationTarget.style.display = 'none';
        }
        this.selectedFolderTextTarget.innerText = modal.location.name;
        this.projectFolderIdInputTarget.value = modal.location.id as string;
      });
  }

  updateForm(evt:InputEvent):void {
    const mode = (evt.target as HTMLInputElement).value;
    const { manual, automatic } = this.lastProjectFoldersValue;

    switch (mode) {
      case 'manual':
        this.projectFolderIdInputTarget.value = manual ?? '';

        this.fetchProjectFolder().subscribe((projectFolder) => {
          this.selectedFolderTextTarget.innerText = projectFolder === null
            ? this.placeholderFolderNameValue
            : projectFolder.name;
        });

        break;
      case 'automatic':
        this.projectFolderIdInputTarget.value = automatic ?? '';
        break;
      default:
        this.projectFolderIdInputTarget.value = '';
    }

    this.folderModeValue = mode;

    this.toggleFolderDisplay(mode);
  }

  private get modalService():Observable<OpModalService> {
    return from(window.OpenProject.getPluginContext())
      .pipe(map((pluginContext) => pluginContext.services.opModalService));
  }

  private get storage():IStorage {
    return JSON.parse(this.storageTarget.dataset.storage as string) as IStorage;
  }

  private get projectFolderHref():string|null {
    const projectFolderId = this.projectFolderIdInputTarget.value;

    if (projectFolderId.length === 0) {
      return null;
    }

    return `${this.storage._links.self.href}/files/${projectFolderId}`;
  }

  private fetchStorageAuthorizationState():Observable<boolean> {
    return from(fetch(this.storage._links.self.href)
      .then((data) => data.json()))
      .pipe(
        map((storage:IStorage) => storage._links.authorizationState.href === storageConnected),
      );
  }

  private fetchProjectFolder():Observable<IStorageFile|null> {
    const href = this.projectFolderHref;
    if (href === null) {
      return of(null);
    }

    return from(fetch(href).then((data) => data.json()))
      .pipe(
        map((file) => {
          // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
          if (file._type === 'StorageFile') {
            return file as IStorageFile;
          }

          return null;
        }),
      );
  }

  private toggleFolderDisplay(value:string):void {
    // If the manual radio button is selected, show the manual folder selection section
    if (this.hasProjectFolderSectionTarget && value === 'manual') {
      this.projectFolderSectionTarget.style.display = 'flex';
    } else {
      this.projectFolderSectionTarget.style.display = 'none';
    }
  }
}

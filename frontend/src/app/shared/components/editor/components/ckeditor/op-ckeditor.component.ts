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
  Component,
  ElementRef,
  EventEmitter,
  Input,
  OnDestroy,
  OnInit,
  Output,
  ViewChild,
} from '@angular/core';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import {
  ICKEditorContext,
  ICKEditorInstance,
  ICKEditorWatchdog,
} from 'core-app/shared/components/editor/components/ckeditor/ckeditor.types';
import { CKEditorSetupService } from 'core-app/shared/components/editor/components/ckeditor/ckeditor-setup.service';
import { KeyCodes } from 'core-app/shared/helpers/keyCodes.enum';
import { debugLog } from 'core-app/shared/helpers/debug_output';

declare module 'codemirror';

@Component({
  selector: 'op-ckeditor',
  templateUrl: './op-ckeditor.html',
  styleUrls: ['./op-ckeditor.sass'],
})
export class OpCkeditorComponent implements OnInit, OnDestroy {
  @Input() context:ICKEditorContext;

  @Input()
  public set content(newVal:string) {
    this._content = newVal || '';

    if (this.initialized) {
      this.ckEditorInstance.setData(this._content);
    }
  }

  // Output notification once ready
  @Output() initializeDone = new EventEmitter<ICKEditorInstance>();

  // Output notification at max once/s for data changes
  @Output() contentChanged = new EventEmitter<string>();

  // Output notification when editor cannot be initialized
  @Output() initializationFailed = new EventEmitter<string>();

  // Output save requests (ctrl+enter and cmd+enter)
  @Output() saveRequested = new EventEmitter<string>();

  // View container of the replacement used to initialize CKEditor5
  @ViewChild('opCkeditorReplacementContainer', { static: true }) opCkeditorReplacementContainer:ElementRef;

  @ViewChild('codeMirrorPane') codeMirrorPane:ElementRef;

  // CKEditor instance once initialized
  public watchdog:ICKEditorWatchdog;

  public ckEditorInstance:ICKEditorInstance;

  public error:string|null = null;

  public allowManualMode = false;

  public manualMode = false;

  private _content = '';

  public text = {
    errorTitle: this.I18n.t('js.editor.ckeditor_error'),
  };

  // Codemirror instance, initialized lazily when running source mode
  public codeMirrorInstance:undefined|any;

  // Debounce change listener for both CKE and codemirror
  // to read back changes as they happen
  private debouncedEmitter = _.debounce(
    () => {
      void this.getTransformedContent(false)
        .then((val) => {
          this.contentChanged.emit(val);
        });
    },
    1000,
    { leading: true },
  );

  private $element:JQuery;

  constructor(
    private readonly elementRef:ElementRef,
    private readonly Notifications:ToastService,
    private readonly I18n:I18nService,
    private readonly configurationService:ConfigurationService,
    private readonly ckEditorSetup:CKEditorSetupService,
  ) {
  }

  /**
   * Get the current live data from CKEditor. This may raise in cases
   * the data cannot be loaded (MS Edge!)
   */
  public getRawData():string {
    if (this.manualMode) {
      return this._content = this.codeMirrorInstance.getValue();
    }
    return this._content = this.ckEditorInstance.getData({ trim: false });
  }

  /**
   * Get a promise with the transformed content, will wrap errors in the promise.
   * @param notificationOnError
   */
  public getTransformedContent(notificationOnError = true):Promise<string> {
    if (!this.initialized) {
      throw new Error('Tried to access CKEditor instance before initialization.');
    }

    return new Promise<string>((resolve, reject) => {
      try {
        resolve(this.getRawData());
      } catch (e) {
        console.error(`Failed to save CKEditor content: ${e}.`);
        const error = this.I18n.t(
          'js.editor.error_saving_failed',
          { error: e || this.I18n.t('js.error.internal') },
        );

        if (notificationOnError) {
          this.Notifications.addError(error);
        }

        reject(error);
      }
    });
  }

  /**
   * Return the current content. This may be outdated a tiny bit.
   */
  public get content() {
    return this._content;
  }

  public get initialized():boolean {
    return this.ckEditorInstance !== undefined;
  }

  ngOnInit() {
    try {
      this.initializeEditor();
    } catch (error:unknown) {
      // We will run into this error if, among others, the browser does not fully support
      // CKEditor's requirements on ES6.

      const message = (error as Error).toString();
      console.error('Failed to setup CKEditor instance: %O', error);
      this.error = message;
      this.initializationFailed.emit(message);
    }
  }

  ngOnDestroy() {
    try {
      this.watchdog?.destroy();
    } catch (e) {
      console.error('Failed to destroy CKEditor instance:', e);
    }
  }

  private initializeEditor() {
    this.$element = jQuery(this.elementRef.nativeElement);

    const editorPromise = this.ckEditorSetup
      .create(
        this.opCkeditorReplacementContainer.nativeElement,
        this.context,
        this.content,
      )
      .catch((error:string) => {
        throw (error);
      })
      .then((watchdog:ICKEditorWatchdog) => {
        this.setupWatchdog(watchdog);
        const editor = watchdog.editor;
        this.ckEditorInstance = editor;


        // Switch mode
        editor.on('op:source-code-enabled', () => this.enableManualMode());
        editor.on('op:source-code-disabled', () => this.disableManualMode());

        // Capture CTRL+ENTER commands
        this.interceptModifiedEnterKeystrokes(editor);

        // Emit global dragend events for other drop zones to react.
        // This is needed, as CKEditor does not bubble any drag events
        const model = watchdog.editor.model;
        model.document.on('change', this.debouncedEmitter);
        model.on('op:attachment-added', () => document.body.dispatchEvent(new DragEvent('dragend')));
        model.on('op:attachment-removed', () => document.body.dispatchEvent(new DragEvent('dragend')));

        this.initializeDone.emit(watchdog.editor);
        return watchdog.editor;
      });

    this.$element.data('editor', editorPromise);
  }

  private interceptModifiedEnterKeystrokes(editor:ICKEditorInstance) {
    editor.listenTo(
      editor.editing.view.document,
      'keydown',
      (evt, data) => {
        if ((data.ctrlKey || data.metaKey) && data.keyCode === KeyCodes.ENTER) {
          debugLog('Sending save request from CKEditor.');
          this.saveRequested.emit();
          evt.stop();
        }
      },
      { priority: 'highest' },
    );
  }

  /**
   * Disable the manual mode, kill the codeMirror instance and switch back to CKEditor
   */
  private disableManualMode() {
    const current = this.getRawData();

    // Apply content to ckeditor
    this.ckEditorInstance.setData(current);
    this.codeMirrorInstance = null;
    this.manualMode = false;
  }

  /**
   * Enable manual mode, get data from WYSIWYG and show CodeMirror instance.
   */
  private enableManualMode() {
    const current = this.getRawData();
    const cmMode = 'gfm';

    Promise
      .all([
        import('codemirror'),
        import(/* webpackChunkName: "codemirror-mode" */ `codemirror/mode/${cmMode}/${cmMode}.js`),
      ])
      .then((imported:any[]) => {
        const CodeMirror = imported[0].default;
        this.codeMirrorInstance = CodeMirror(
          this.$element.find('.ck-editor__source')[0],
          {
            lineNumbers: true,
            smartIndent: true,
            value: current,
            mode: '',
          },
        );

        this.codeMirrorInstance.on('change', this.debouncedEmitter);
        setTimeout(() => this.codeMirrorInstance.refresh(), 100);
        this.manualMode = true;
      });
  }

  /**
   * Listen to some of the error events of the watchdog to provide the
   * user with some information on what went wrong.
   *
   * @param watchdog
   * @private
   */
  private setupWatchdog(watchdog:ICKEditorWatchdog) {
    this.watchdog = watchdog;

    watchdog.on('error', (_, { error }) => {
      this.error = error.message;
    });
  }
}

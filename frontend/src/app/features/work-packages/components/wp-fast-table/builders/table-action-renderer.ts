import { Injector } from '@angular/core';
import { OpTableActionsService } from 'core-app/features/work-packages/components/wp-table/table-actions/table-actions.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { contextMenuSpanClassName, contextMenuTdClassName } from 'core-app/features/work-packages/components/wp-table/table-actions/table-action';
import { internalContextMenuColumn } from 'core-app/features/work-packages/components/wp-fast-table/builders/internal-sort-columns';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { tdClassName } from './cell-builder';

export class TableActionRenderer {
  // Injections
  @InjectField() tableActionsService:OpTableActionsService;

  constructor(public readonly injector:Injector) {
  }

  public build(workPackage:WorkPackageResource):HTMLElement {
    // Append details button
    const td = document.createElement('td');
    td.classList.add(tdClassName, contextMenuTdClassName, internalContextMenuColumn.id, 'hide-when-print');

    // Wrap any actions in a span
    const span = document.createElement('span');
    span.classList.add(contextMenuSpanClassName);

    this.tableActionsService
      .render(workPackage)
      .forEach((el:HTMLElement) => {
        span.appendChild(el);
      });

    td.appendChild(span);
    return td;
  }
}

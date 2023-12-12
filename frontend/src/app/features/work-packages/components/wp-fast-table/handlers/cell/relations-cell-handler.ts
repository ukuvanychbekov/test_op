import { Injector } from '@angular/core';
import { WorkPackageViewRelationColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-relation-columns.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { relationCellIndicatorClassName, relationCellTdClassName } from '../../builders/relation-cell-builder';
import { tableRowClassName } from '../../builders/rows/single-row-builder';
import { WorkPackageTable } from '../../wp-fast-table';
import { ClickOrEnterHandler } from '../click-or-enter-handler';
import { TableEventComponent, TableEventHandler } from '../table-handler-registry';

export class RelationsCellHandler extends ClickOrEnterHandler implements TableEventHandler {
  // Injections
  @InjectField() wpTableRelationColumns:WorkPackageViewRelationColumnsService;

  public get EVENT() {
    return 'click.table.relationsCell, keydown.table.relationsCell';
  }

  public get SELECTOR() {
    return `.${relationCellIndicatorClassName}`;
  }

  public eventScope(view:TableEventComponent) {
    return jQuery(view.workPackageTable.tableAndTimelineContainer);
  }

  constructor(public readonly injector:Injector) {
    super();
  }

  protected processEvent(table:WorkPackageTable, evt:JQuery.TriggeredEvent):boolean {
    debugLog('Handled click on relation cell %o', evt.target);
    evt.preventDefault();

    // Locate the relation td
    const td = jQuery(evt.target).closest(`.${relationCellTdClassName}`);
    const columnId = td.data('columnId');

    // Locate the row
    const rowElement = jQuery(evt.target).closest(`.${tableRowClassName}`);
    const workPackageId = rowElement.data('workPackageId');

    // If currently expanded
    if (this.wpTableRelationColumns.getExpandFor(workPackageId) === columnId) {
      this.wpTableRelationColumns.collapse(workPackageId);
    } else {
      this.wpTableRelationColumns.setExpandFor(workPackageId, columnId);
    }

    return false;
  }
}

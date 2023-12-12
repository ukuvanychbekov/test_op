import { Injector } from '@angular/core';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { take, takeUntil } from 'rxjs/operators';
import { WorkPackageInlineCreateService } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { TableDragActionsRegistryService } from 'core-app/features/work-packages/components/wp-table/drag-and-drop/actions/table-drag-actions-registry.service';
import { TableDragActionService } from 'core-app/features/work-packages/components/wp-table/drag-and-drop/actions/table-drag-action.service';
import { States } from 'core-app/core/states/states.service';
import { tableRowClassName } from 'core-app/features/work-packages/components/wp-fast-table/builders/rows/single-row-builder';
import { DragAndDropService } from 'core-app/shared/helpers/drag-and-drop/drag-and-drop.service';
import { reinsert } from 'core-app/shared/helpers/drag-and-drop/drag-and-drop.helpers';
import { WorkPackageViewOrderService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-order.service';
import { BrowserDetector } from 'core-app/core/browser/browser-detector.service';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { isInsideCollapsedGroup } from 'core-app/features/work-packages/components/wp-fast-table/helpers/wp-table-row-helpers';
import { collapsedGroupClass } from 'core-app/features/work-packages/components/wp-fast-table/helpers/wp-table-hierarchy-helpers';
import { WorkPackageTable } from '../../wp-fast-table';
import { firstValueFrom } from 'rxjs';

export class DragAndDropTransformer {
  @InjectField() private readonly states:States;

  @InjectField() private readonly querySpace:IsolatedQuerySpace;

  @InjectField() private readonly inlineCreateService:WorkPackageInlineCreateService;

  @InjectField() private readonly halNotification:HalResourceNotificationService;

  @InjectField() private readonly wpTableSortBy:WorkPackageViewSortByService;

  @InjectField() private readonly wpTableOrder:WorkPackageViewOrderService;

  @InjectField() private readonly browserDetector:BrowserDetector;

  @InjectField() private readonly apiV3Service:ApiV3Service;

  @InjectField() private readonly wpListService:WorkPackagesListService;

  @InjectField() private readonly dragActionRegistry:TableDragActionsRegistryService;

  @InjectField(DragAndDropService, null) private readonly dragService:DragAndDropService|null;

  constructor(public readonly injector:Injector,
    public table:WorkPackageTable) {
    // The DragService may not have been provided
    // in which case we do not provide drag and drop
    if (this.dragService === null) {
      return;
    }

    this.inlineCreateService.newInlineWorkPackageCreated
      .pipe(takeUntil(this.querySpace.stopAllSubscriptions))
      .subscribe(async (wpId) => {
        const newOrder = await this.wpTableOrder.add(this.currentOrder, wpId);
        this.updateRenderedOrder(newOrder);
      });

    this.querySpace.stopAllSubscriptions
      .pipe(take(1))
      .subscribe(() => {
        this.dragService!.remove(this.table.tbody);
      });

    this.dragService.register({
      dragContainer: this.table.tbody,
      scrollContainers: [this.table.scrollContainer],
      accepts: () => true,
      moves: (el:any, source:any, handle:HTMLElement) => {
        if (!handle.classList.contains('wp-table--drag-and-drop-handle')) {
          return false;
        }

        const wpId:string = el.dataset.workPackageId!;
        const workPackage = this.states.workPackages.get(wpId).value;
        return !!workPackage && this.actionService.canPickup(workPackage);
      },
      // eslint-disable-next-line @typescript-eslint/no-misused-promises
      onMoved: async (el:HTMLElement, target:HTMLElement, source:HTMLElement, sibling:HTMLElement|null) => {
        const wpId:string = el.dataset.workPackageId!;
        let rowIndex;

        try {
          const workPackage = await firstValueFrom(this.apiV3Service.work_packages.id(wpId).get());

          if (isInsideCollapsedGroup(sibling)) {
            const collapsedGroupCSSClass = Array.from(sibling!.classList).find((listClass) => listClass.includes(collapsedGroupClass()))!;
            const collapsedGroupId = collapsedGroupCSSClass.replace(collapsedGroupClass(), '');
            const collapsedGroupElements = source.getElementsByClassName(collapsedGroupClass(collapsedGroupId));
            const collapsedGroupLastChild = collapsedGroupElements[collapsedGroupElements.length - 1];
            rowIndex = this.findRowIndex(collapsedGroupLastChild as HTMLElement);
          } else {
            rowIndex = this.findRowIndex(el);
          }

          const newOrder = await this.wpTableOrder.move(this.currentOrder, wpId, rowIndex);

          await this.actionService.handleDrop(workPackage, el);
          this.updateRenderedOrder(newOrder);
          this.actionService.onNewOrder(newOrder);

          // Save the query when switching to manual
          const query = this.querySpace.query.value;
          if (query && this.wpTableSortBy.switchToManualSorting(query)) {
            await this.wpListService.createOrSave(query);
          }
        } catch (e) {
          this.halNotification.handleRawError(e);

          // Restore original element's styles
          this.actionService.changeShadowElement(el, true);
          // Restore element in from container
          reinsert(el, el.dataset.sourceIndex || -1, source);
        }
      },
      onRemoved: (el:HTMLElement) => {
        const wpId:string = el.dataset.workPackageId!;
        const newOrder = this.wpTableOrder.remove(this.currentOrder, wpId);
        this.updateRenderedOrder(newOrder);
      },
      onAdded: async (el:HTMLElement) => {
        const wpId:string = el.dataset.workPackageId!;
        const workPackage = await firstValueFrom(this.apiV3Service.work_packages.id(wpId).get());
        const rowIndex = this.findRowIndex(el);

        return this.actionService
          .handleDrop(workPackage, el)
          .then(async () => {
            const newOrder = await this.wpTableOrder.add(this.currentOrder, wpId, rowIndex);
            this.updateRenderedOrder(newOrder);
            this.actionService.onNewOrder(newOrder);

            return true;
          })
          .catch(() => false);
      },
      // eslint-disable-next-line @typescript-eslint/no-misused-promises
      onCloned: async (clone:HTMLElement, original:HTMLElement) => {
        // Replace clone with one TD of the subject
        const wpId:string = original.dataset.workPackageId!;
        const workPackage = await firstValueFrom(this.apiV3Service.work_packages.id(wpId).get());

        const colspan = clone.children.length;
        const td = document.createElement('td');
        td.textContent = workPackage.subjectWithId();
        td.colSpan = colspan;
        td.classList.add('wp-table--cell-td', 'subject');

        clone.style.maxWidth = '500px';
        clone.innerHTML = td.outerHTML;
      },
      onShadowInserted: (el:HTMLElement) => {
        if (!this.browserDetector.isEdge) {
          this.actionService.changeShadowElement(el);
        }
      },
      onCancel: (el:HTMLElement) => {
        if (!this.browserDetector.isEdge) {
          this.actionService.changeShadowElement(el, true);
        }
      },
    });
  }

  /**
   * Update current rendered order
   */
  private async updateRenderedOrder(order:string[]) {
    order = _.uniq(order);

    const mappedOrder = await Promise.all(
      order.map(
        (wpId) => firstValueFrom(this.apiV3Service.work_packages.id(wpId).get()),
      ),
    );

    /** Re-render the table */
    this.table.initialSetup(mappedOrder);
  }

  protected get actionService():TableDragActionService {
    return this.dragActionRegistry.get(this.injector);
  }

  protected get currentOrder():string[] {
    return this
      .currentRenderedOrder
      .map((row) => row.workPackageId!);
  }

  protected get currentRenderedOrder():RenderedWorkPackage[] {
    return this
      .querySpace
      .renderedWorkPackages
      .getValueOr([]);
  }

  /**
   * Find the index of the row in the set of rendered work packages.
   * This will skip non-work-package rows such as group headers
   * @param el
   */
  private findRowIndex(el:HTMLElement):number {
    const rows = Array.from(this.table.tbody.getElementsByClassName(tableRowClassName));
    return rows.indexOf(el) || 0;
  }
}

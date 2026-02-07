import { Component, input } from '@angular/core';
import { MatChipsModule } from '@angular/material/chips';
import { ReportStatus } from '../../../models/report.model';

@Component({
  selector: 'app-status-chip',
  standalone: true,
  imports: [MatChipsModule],
  template: ` <mat-chip-row [class]="statusClass()">{{ status() }}</mat-chip-row> `,
  styles: [
    `
      :host ::ng-deep .mat-mdc-chip-row {
        font-weight: 500;
      }
      :host ::ng-deep .status-new {
        --mdc-chip-elevated-container-color: #e3f2fd;
        color: #1565c0;
      }
      :host ::ng-deep .status-inreview {
        --mdc-chip-elevated-container-color: #fff3e0;
        color: #e65100;
      }
      :host ::ng-deep .status-resolved {
        --mdc-chip-elevated-container-color: #e8f5e9;
        color: #2e7d32;
      }
    `,
  ],
})
export class StatusChipComponent {
  status = input.required<ReportStatus>();

  statusClass(): string {
    const s = this.status();
    if (s === 'Resolved') return 'status-resolved';
    if (s === 'InReview') return 'status-inreview';
    return 'status-new';
  }
}

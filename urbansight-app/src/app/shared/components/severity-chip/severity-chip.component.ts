import { Component, input } from '@angular/core';
import { MatChipsModule } from '@angular/material/chips';
import { Severity } from '../../../models/report.model';

@Component({
  selector: 'app-severity-chip',
  standalone: true,
  imports: [MatChipsModule],
  template: ` <mat-chip-row [class]="severityClass()">{{ severity() }}</mat-chip-row> `,
  styles: [
    `
      :host ::ng-deep .mat-mdc-chip-row {
        font-weight: 500;
      }
      :host ::ng-deep .severity-low {
        --mdc-chip-elevated-container-color: #e8f5e9;
        color: #2e7d32;
      }
      :host ::ng-deep .severity-medium {
        --mdc-chip-elevated-container-color: #fff8e1;
        color: #f57c00;
      }
      :host ::ng-deep .severity-high {
        --mdc-chip-elevated-container-color: #ffebee;
        color: #c62828;
      }
    `,
  ],
})
export class SeverityChipComponent {
  severity = input.required<Severity>();

  severityClass(): string {
    const s = this.severity();
    if (s === 'High') return 'severity-high';
    if (s === 'Medium') return 'severity-medium';
    return 'severity-low';
  }
}

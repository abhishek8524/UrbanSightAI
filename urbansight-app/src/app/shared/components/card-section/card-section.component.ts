import { Component, input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';

@Component({
  selector: 'app-card-section',
  standalone: true,
  imports: [CommonModule, MatCardModule],
  template: `
    <mat-card class="card-section" [class.elevated]="elevated()">
      @if (title()) {
        <mat-card-header>
          <mat-card-title>{{ title() }}</mat-card-title>
        </mat-card-header>
      }
      <mat-card-content>
        <ng-content></ng-content>
      </mat-card-content>
    </mat-card>
  `,
  styles: [
    `
      .card-section {
        border-radius: 12px;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
        transition: box-shadow 0.2s ease;
      }
      .card-section.elevated {
        box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
      }
      .card-section:hover {
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
      }
      mat-card-header {
        margin-bottom: 0.5rem;
      }
      mat-card-title {
        font-size: 1.25rem;
        font-weight: 600;
      }
    `,
  ],
})
export class CardSectionComponent {
  title = input<string>('');
  elevated = input<boolean>(false);
}

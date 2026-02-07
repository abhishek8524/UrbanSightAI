import { Component, OnInit, signal, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { CommonModule } from '@angular/common';
import { MatTableModule, MatTableDataSource } from '@angular/material/table';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatSelectModule } from '@angular/material/select';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatChipsModule } from '@angular/material/chips';
import { FormsModule } from '@angular/forms';
import { ReportService } from '../../../core/services/report.service';
import { Report, IssueType, ReportStatus, ISSUE_TYPE_LABELS } from '../../../models/report.model';
import { SeverityChipComponent } from '../../../shared/components/severity-chip/severity-chip.component';

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [
    CommonModule,
    RouterLink,
    MatTableModule,
    MatButtonModule,
    MatFormFieldModule,
    MatSelectModule,
    MatProgressSpinnerModule,
    MatChipsModule,
    FormsModule,
    SeverityChipComponent,
  ],
  template: `
    <div class="dashboard">
      <div class="header">
        <h1>Admin dashboard</h1>
        <p>Priority-sorted reports. Update status and open details.</p>
      </div>
      <div class="filters">
        <mat-form-field appearance="outline">
          <mat-label>Issue type</mat-label>
          <mat-select [(ngModel)]="filterType" (selectionChange)="applyFilter()">
            <mat-option value="">All</mat-option>
            @for (opt of issueTypeOptions; track opt.value) {
              <mat-option [value]="opt.value">{{ opt.label }}</mat-option>
            }
          </mat-select>
        </mat-form-field>
        <mat-form-field appearance="outline">
          <mat-label>Status</mat-label>
          <mat-select [(ngModel)]="filterStatus" (selectionChange)="applyFilter()">
            <mat-option value="">All</mat-option>
            <mat-option value="New">New</mat-option>
            <mat-option value="InReview">In Review</mat-option>
            <mat-option value="Resolved">Resolved</mat-option>
          </mat-select>
        </mat-form-field>
      </div>
      @if (loading()) {
        <div class="loading"><mat-spinner diameter="40"></mat-spinner></div>
      } @else {
        <div class="table-wrap">
          <table mat-table [dataSource]="dataSource" class="priority-table">
            <ng-container matColumnDef="type">
              <th mat-header-cell *matHeaderCellDef>Type</th>
              <td mat-cell *matCellDef="let r">{{ issueTypeLabel(r.issueType) }}</td>
            </ng-container>
            <ng-container matColumnDef="severity">
              <th mat-header-cell *matHeaderCellDef>Severity</th>
              <td mat-cell *matCellDef="let r"><app-severity-chip [severity]="r.severity" /></td>
            </ng-container>
            <ng-container matColumnDef="status">
              <th mat-header-cell *matHeaderCellDef>Status</th>
              <td mat-cell *matCellDef="let r">
                <mat-select [value]="r.status" (selectionChange)="updateStatus(r.id!, $event.value)">
                  <mat-option value="New">New</mat-option>
                  <mat-option value="InReview">In Review</mat-option>
                  <mat-option value="Resolved">Resolved</mat-option>
                </mat-select>
              </td>
            </ng-container>
            <ng-container matColumnDef="upvotes">
              <th mat-header-cell *matHeaderCellDef>Upvotes</th>
              <td mat-cell *matCellDef="let r">{{ r.upvotes ?? 0 }}</td>
            </ng-container>
            <ng-container matColumnDef="summary">
              <th mat-header-cell *matHeaderCellDef>Summary</th>
              <td mat-cell *matCellDef="let r">{{ (r.aiSummary || '').slice(0, 60) }}…</td>
            </ng-container>
            <ng-container matColumnDef="actions">
              <th mat-header-cell *matHeaderCellDef>Actions</th>
              <td mat-cell *matCellDef="let r">
                <a mat-button [routerLink]="['/admin/report', r.id]">View</a>
              </td>
            </ng-container>
            <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
            <tr mat-row *matRowDef="let row; columns: displayedColumns"></tr>
          </table>
        </div>
        <div class="stats">
          <span>Total: {{ filteredReports.length }}</span>
          <a mat-button routerLink="/admin/map">View on map</a>
        </div>
      }
    </div>
  `,
  styles: [
    `
      .dashboard {
        max-width: 1200px;
        margin: 0 auto;
        padding: 2rem 1rem;
      }
      .header h1 {
        font-size: 1.75rem;
        margin: 0 0 0.25rem;
      }
      .header p {
        margin: 0 0 1.5rem;
        color: #546e7a;
      }
      .filters {
        display: flex;
        gap: 1rem;
        margin-bottom: 1.5rem;
      }
      .filters mat-form-field {
        min-width: 160px;
      }
      .loading {
        display: flex;
        justify-content: center;
        padding: 3rem;
      }
      .table-wrap {
        overflow: auto;
        border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
      }
      .priority-table {
        width: 100%;
      }
      .priority-table th {
        font-weight: 600;
      }
      .priority-table mat-select {
        min-width: 120px;
      }
      .stats {
        margin-top: 1rem;
        display: flex;
        align-items: center;
        gap: 1rem;
      }
    `,
  ],
})
export class AdminDashboardComponent implements OnInit {
  private reportService = inject(ReportService);
  loading = signal(true);
  reports = signal<Report[]>([]);
  filterType: IssueType | '' = '';
  filterStatus: ReportStatus | '' = '';
  issueTypeOptions = Object.entries(ISSUE_TYPE_LABELS).map(([value, label]) => ({ value, label }));
  displayedColumns = ['type', 'severity', 'status', 'upvotes', 'summary', 'actions'];
  dataSource = new MatTableDataSource<Report>([]);

  get filteredReports(): Report[] {
    const list = this.reports();
    return list.filter((r) => {
      if (this.filterType && r.issueType !== this.filterType) return false;
      if (this.filterStatus && r.status !== this.filterStatus) return false;
      return true;
    });
  }

  ngOnInit(): void {
    this.reportService.getAdminPriorityReports().then((list: Report[]) => {
      this.reports.set(list);
      this.applyFilter();
      this.loading.set(false);
    });
  }

  applyFilter(): void {
    this.dataSource.data = this.filteredReports;
  }

  issueTypeLabel(type: IssueType): string {
    return ISSUE_TYPE_LABELS[type] ?? type;
  }

  updateStatus(id: string, status: ReportStatus): void {
    this.reportService.updateStatus(id, status).then(() => {
      this.reports.update((list) =>
        list.map((r) => (r.id === id ? { ...r, status } : r))
      );
      this.dataSource.data = this.filteredReports;
    });
  }
}

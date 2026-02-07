import { Component, OnInit, signal, inject } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { CommonModule } from '@angular/common';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatSelectModule } from '@angular/material/select';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { FormsModule } from '@angular/forms';
import { ReportService } from '../../../core/services/report.service';
import { Report, ReportStatus, ISSUE_TYPE_LABELS } from '../../../models/report.model';
import { SeverityChipComponent } from '../../../shared/components/severity-chip/severity-chip.component';
import { StatusChipComponent } from '../../../shared/components/status-chip/status-chip.component';

@Component({
  selector: 'app-admin-report-detail',
  standalone: true,
  imports: [
    CommonModule,
    RouterLink,
    MatButtonModule,
    MatFormFieldModule,
    MatSelectModule,
    MatProgressSpinnerModule,
    FormsModule,
    SeverityChipComponent,
    StatusChipComponent,
  ],
  template: `
    <div class="admin-detail-container">
      @if (loading()) {
        <div class="loading"><mat-spinner diameter="40"></mat-spinner></div>
      } @else if (report()) {
        <div class="admin-detail-card">
          <img [src]="report()!.imageUrl" alt="Report" class="report-image" />
          <div class="meta">
            <app-severity-chip [severity]="report()!.severity" />
            <app-status-chip [status]="report()!.status" />
            <span class="type">{{ issueTypeLabel(report()!.issueType) }}</span>
            <span class="date">{{ dateLabel(report()!.createdAt) }}</span>
          </div>
          <div class="status-control">
            <mat-form-field appearance="outline">
              <mat-label>Status</mat-label>
              <mat-select [value]="report()!.status" (selectionChange)="updateStatus($event.value)">
                <mat-option value="New">New</mat-option>
                <mat-option value="InReview">In Review</mat-option>
                <mat-option value="Resolved">Resolved</mat-option>
              </mat-select>
            </mat-form-field>
          </div>
          <h2>AI summary</h2>
          <p class="ai-summary">{{ report()!.aiSummary }}</p>
          @if (report()!.userDescription) {
            <h3>Citizen description</h3>
            <p class="user-desc">{{ report()!.userDescription }}</p>
          }
          <p class="upvotes">👍 {{ report()!.upvotes }} upvotes</p>
          <div class="actions">
            <a mat-button routerLink="/admin/dashboard">Back to dashboard</a>
            <a mat-button routerLink="/admin/map">View on map</a>
          </div>
        </div>
      } @else {
        <p class="error">Report not found.</p>
        <a mat-button routerLink="/admin/dashboard">Back to dashboard</a>
      }
    </div>
  `,
  styles: [
    `
      .admin-detail-container {
        max-width: 640px;
        margin: 2rem auto;
        padding: 0 1rem;
      }
      .loading {
        display: flex;
        justify-content: center;
        padding: 3rem;
      }
      .admin-detail-card {
        background: white;
        border-radius: 12px;
        box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
        overflow: hidden;
      }
      .report-image {
        width: 100%;
        max-height: 360px;
        object-fit: cover;
      }
      .meta {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        gap: 0.5rem;
        padding: 1rem 1.25rem;
        border-bottom: 1px solid #eee;
      }
      .type {
        font-weight: 500;
        color: #374151;
      }
      .date {
        color: #6b7280;
        font-size: 0.875rem;
        margin-left: auto;
      }
      .status-control {
        padding: 0 1.25rem 1rem;
      }
      .status-control mat-form-field {
        width: 100%;
        max-width: 200px;
      }
      .admin-detail-card h2,
      .admin-detail-card h3 {
        font-size: 1rem;
        margin: 1rem 1.25rem 0.25rem;
      }
      .ai-summary,
      .user-desc {
        margin: 0 1.25rem 1rem;
        line-height: 1.5;
        color: #374151;
      }
      .upvotes {
        margin: 0 1.25rem;
        font-size: 0.9rem;
      }
      .actions {
        display: flex;
        gap: 0.5rem;
        margin: 1rem 1.25rem;
      }
      .error {
        color: #c62828;
        margin-bottom: 1rem;
      }
    `,
  ],
})
export class AdminReportDetailComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private reportService = inject(ReportService);
  report = signal<Report | null>(null);
  loading = signal(true);

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.reportService.getReportById(id).then((r) => {
        this.report.set(r ?? null);
        this.loading.set(false);
      });
    } else {
      this.loading.set(false);
    }
  }

  issueTypeLabel(type: Report['issueType']): string {
    return ISSUE_TYPE_LABELS[type] ?? type;
  }

  dateLabel(ts: number): string {
    if (!ts) return '';
    return new Date(ts).toLocaleDateString(undefined, {
      dateStyle: 'medium',
      timeStyle: 'short',
    });
  }

  updateStatus(status: ReportStatus): void {
    const r = this.report();
    if (!r?.id) return;
    this.reportService.updateStatus(r.id, status).then(() => {
      this.report.set({ ...r, status });
    });
  }
}

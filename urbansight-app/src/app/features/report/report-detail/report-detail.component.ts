import { Component, OnInit, signal, inject } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { CommonModule } from '@angular/common';
import { MatButtonModule } from '@angular/material/button';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { ReportService } from '../../../core/services/report.service';
import { ToastService } from '../../../core/services/toast.service';
import { Report, ISSUE_TYPE_LABELS } from '../../../models/report.model';
import { SeverityChipComponent } from '../../../shared/components/severity-chip/severity-chip.component';
import { StatusChipComponent } from '../../../shared/components/status-chip/status-chip.component';

@Component({
  selector: 'app-report-detail',
  standalone: true,
  imports: [
    CommonModule,
    RouterLink,
    MatButtonModule,
    MatProgressSpinnerModule,
    SeverityChipComponent,
    StatusChipComponent,
  ],
  template: `
    <div class="detail-container">
      @if (loading()) {
        <div class="loading"><mat-spinner diameter="40"></mat-spinner></div>
      } @else if (report()) {
        <div class="detail-card">
          <img [src]="report()!.imageUrl" alt="Report" class="report-image" />
          <div class="meta">
            <app-severity-chip [severity]="report()!.severity" />
            <app-status-chip [status]="report()!.status" />
            <span class="type">{{ issueTypeLabel(report()!.issueType) }}</span>
            <span class="date">{{ dateLabel(report()!.createdAt) }}</span>
          </div>
          <h2>AI summary</h2>
          <p class="ai-summary">{{ report()!.aiSummary }}</p>
          @if (report()!.userDescription) {
            <h3>Your description</h3>
            <p class="user-desc">{{ report()!.userDescription }}</p>
          }
          <p class="upvotes">👍 {{ report()!.upvotes }} upvotes</p>
          <button mat-stroked-button (click)="upvote()" [disabled]="upvoted()">Upvote</button>
          <a mat-button routerLink="/map">Back to map</a>
        </div>
      } @else {
        <p class="error">Report not found.</p>
        <a mat-button routerLink="/">Go home</a>
      }
    </div>
  `,
  styles: [
    `
      .detail-container {
        max-width: 640px;
        margin: 2rem auto;
        padding: 0 1rem;
      }
      .loading {
        display: flex;
        justify-content: center;
        padding: 3rem;
      }
      .detail-card {
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
      .detail-card h2,
      .detail-card h3 {
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
      .detail-card button,
      .detail-card a {
        margin: 0 1.25rem 1rem;
      }
      .error {
        color: #c62828;
        margin-bottom: 1rem;
      }
    `,
  ],
})
export class ReportDetailComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private reportService = inject(ReportService);
  private toast = inject(ToastService);
  report = signal<Report | null>(null);
  loading = signal(true);
  upvoted = signal(false);

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

  upvote(): void {
    const r = this.report();
    if (!r?.id || this.upvoted()) return;
    this.reportService.upvote(r.id).then(() => {
      this.upvoted.set(true);
      this.report.set({ ...r, upvotes: (r.upvotes ?? 0) + 1 });
      this.toast.success('Thanks for your upvote!');
    });
  }
}

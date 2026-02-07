import { Injectable } from '@angular/core';
import { BehaviorSubject, map, tap } from 'rxjs';
import { FirebaseService } from './firebase.service';
import {
  Report,
  ReportCreate,
  ReportStatus,
  IssueType,
  Severity,
  GeminiAnalysisResult,
} from '../../models/report.model';

@Injectable({ providedIn: 'root' })
export class ReportService {
  private reports$ = new BehaviorSubject<Report[]>([]);
  private loading$ = new BehaviorSubject<boolean>(false);

  constructor(private firebase: FirebaseService) {}

  getReports() {
    return this.reports$.asObservable();
  }

  getLoading() {
    return this.loading$.asObservable();
  }

  loadReports(): Promise<Report[]> {
    this.loading$.next(true);
    return this.firebase
      .getReports()
      .then((list) => {
        this.reports$.next(list);
        return list;
      })
      .finally(() => this.loading$.next(false));
  }

  loadReportsForMap(): Promise<Report[]> {
    return this.firebase.getReportsForMap();
  }

  getReportById(id: string): Promise<Report | null> {
    return this.firebase.getReport(id);
  }

  async submitReport(create: ReportCreate): Promise<{ reportId: string }> {
    const reportId = await this.firebase.createReport({
      imageUrl: create.imageUrl,
      lat: create.lat,
      lng: create.lng,
      userDescription: create.userDescription ?? '',
      issueType: 'other',
      severity: 'Low',
      aiSummary: 'Analysis pending…',
      status: 'New',
      upvotes: 0,
    });
    return { reportId };
  }

  async runAnalysis(reportId: string, imageUrl: string, userDescription?: string): Promise<GeminiAnalysisResult | null> {
    try {
      const result = await this.firebase.triggerAnalyzeReport(reportId, imageUrl, userDescription);
      const data = (result as { data?: GeminiAnalysisResult })?.data;
      return data ?? null;
    } catch {
      return null;
    }
  }

  updateStatus(id: string, status: ReportStatus): Promise<void> {
    return this.firebase.updateReportStatus(id, status);
  }

  upvote(id: string): Promise<void> {
    return this.firebase.upvoteReport(id);
  }

  getAdminPriorityReports(): Promise<Report[]> {
    this.loading$.next(true);
    return this.firebase
      .getReports(500)
      .then((list) => {
        const severityOrder: Record<Severity, number> = { High: 3, Medium: 2, Low: 1 };
        const sorted = [...list].sort((a, b) => {
          const sev = severityOrder[b.severity] - severityOrder[a.severity];
          if (sev !== 0) return sev;
          const up = (b.upvotes ?? 0) - (a.upvotes ?? 0);
          if (up !== 0) return up;
          return (b.createdAt ?? 0) - (a.createdAt ?? 0);
        });
        return sorted;
      })
      .finally(() => this.loading$.next(false));
  }
}

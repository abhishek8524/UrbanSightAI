import { Component, signal, computed } from '@angular/core';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { MatStepperModule, MatStepper } from '@angular/material/stepper';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { FormsModule } from '@angular/forms';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { FirebaseService } from '../../../core/services/firebase.service';
import { ReportService } from '../../../core/services/report.service';
import { ToastService } from '../../../core/services/toast.service';
import { SkeletonLoaderComponent } from '../../../shared/components/skeleton-loader/skeleton-loader.component';
import { CardSectionComponent } from '../../../shared/components/card-section/card-section.component';
import { SeverityChipComponent } from '../../../shared/components/severity-chip/severity-chip.component';
import { ISSUE_TYPE_LABELS } from '../../../models/report.model';
import type { IssueType, Severity } from '../../../models/report.model';

@Component({
  selector: 'app-report-wizard',
  standalone: true,
  imports: [
    CommonModule,
    MatStepperModule,
    MatButtonModule,
    MatFormFieldModule,
    MatInputModule,
    FormsModule,
    MatProgressSpinnerModule,
    SkeletonLoaderComponent,
    CardSectionComponent,
    SeverityChipComponent,
  ],
  template: `
    <div class="wizard-container">
      <app-card-section title="Report an issue" [elevated]="true">
        <mat-stepper #stepper linear>
          <mat-step label="Photo">
            <div class="step-content">
              <div
                class="drop-zone"
                [class.dragover]="dragOver()"
                (click)="fileInput.click()"
                (dragover)="onDragOver($event)"
                (dragleave)="dragOver.set(false)"
                (drop)="onDrop($event)"
              >
                @if (!previewUrl()) {
                  <p>Drag and drop a photo here, or click to select</p>
                } @else {
                  <img [src]="previewUrl()" alt="Preview" class="preview-img" />
                }
              </div>
              <input
                #fileInput
                type="file"
                accept="image/*"
                (change)="onFileSelected($event)"
                hidden
              />
            </div>
            <div class="stepper-actions">
              <button mat-button matStepperNext [disabled]="!selectedFile()">Next</button>
            </div>
          </mat-step>
          <mat-step label="Location">
            <div class="step-content">
              <p class="step-desc">Confirm or set the location on the map.</p>
              <div id="report-map" class="report-map"></div>
              <p class="map-hint">Click on the map to set the pin. Default: current location if available.</p>
            </div>
            <div class="stepper-actions">
              <button mat-button matStepperPrevious>Back</button>
              <button mat-button matStepperNext [disabled]="!lat()">Next</button>
            </div>
          </mat-step>
          <mat-step label="Description">
            <div class="step-content">
              <mat-form-field appearance="outline" class="full-width">
                <mat-label>Additional details (optional)</mat-label>
                <textarea matInput [(ngModel)]="userDescription" rows="3" placeholder="e.g. Near the bus stop, large pothole"></textarea>
              </mat-form-field>
            </div>
            <div class="stepper-actions">
              <button mat-button matStepperPrevious>Back</button>
              <button mat-button matStepperNext>Next</button>
            </div>
          </mat-step>
          <mat-step label="Submit">
            <div class="step-content">
              @if (!submitted()) {
                <p>Review and submit your report.</p>
                <button mat-raised-button color="primary" (click)="submit(stepper)" [disabled]="submitting()">
                  @if (submitting()) {
                    <mat-spinner diameter="20"></mat-spinner>
                    <span>Submitting…</span>
                  } @else {
                    Submit report
                  }
                </button>
              } @else if (analyzing()) {
                <p class="analyzing-text">AI is analyzing your report…</p>
                <app-skeleton-loader></app-skeleton-loader>
              } @else if (reportResult()) {
                <p class="success-text">Report submitted and analyzed.</p>
                <div class="result-summary">
                  <span><strong>Type:</strong> {{ issueTypeLabel(reportResult()!.issueType) }}</span>
                  <app-severity-chip [severity]="reportResult()!.severity" />
                  <p class="ai-summary">{{ reportResult()!.aiSummary }}</p>
                </div>
                <button mat-raised-button color="primary" (click)="goToReport()">View report</button>
              }
            </div>
          </mat-step>
        </mat-stepper>
      </app-card-section>
    </div>
  `,
  styles: [
    `
      .wizard-container {
        max-width: 640px;
        margin: 2rem auto;
        padding: 0 1rem;
      }
      .step-content {
        min-height: 200px;
        padding: 0.5rem 0;
      }
      .drop-zone {
        border: 2px dashed #b0bec5;
        border-radius: 12px;
        padding: 2rem;
        text-align: center;
        cursor: pointer;
        transition: border-color 0.2s, background 0.2s;
      }
      .drop-zone:hover,
      .drop-zone.dragover {
        border-color: var(--primary);
        background: rgba(0, 120, 130, 0.04);
      }
      .preview-img {
        max-width: 100%;
        max-height: 280px;
        object-fit: contain;
      }
      .step-desc,
      .map-hint {
        color: #546e7a;
        font-size: 0.9rem;
      }
      .report-map {
        height: 280px;
        width: 100%;
        border-radius: 8px;
        margin: 1rem 0;
      }
      .full-width {
        width: 100%;
      }
      .stepper-actions {
        margin-top: 1rem;
        display: flex;
        gap: 0.5rem;
      }
      .analyzing-text,
      .success-text {
        font-weight: 500;
        margin-bottom: 1rem;
      }
      .result-summary {
        margin: 1rem 0;
      }
      .result-summary app-severity-chip {
        display: inline-block;
        margin-left: 0.5rem;
      }
      .ai-summary {
        margin-top: 0.75rem;
        padding: 0.75rem;
        background: #f5f7fa;
        border-radius: 8px;
        line-height: 1.5;
      }
    `,
  ],
})
export class ReportWizardComponent {
  selectedFile = signal<File | null>(null);
  previewUrl = signal<string | null>(null);
  dragOver = signal(false);
  lat = signal<number | null>(null);
  lng = signal<number | null>(null);
  userDescription = '';
  submitted = signal(false);
  submitting = signal(false);
  analyzing = signal(false);
  reportResult = signal<{ issueType: IssueType; severity: Severity; aiSummary: string } | null>(null);
  createdReportId = signal<string | null>(null);
  private map: google.maps.Map | null = null;
  private marker: google.maps.Marker | null = null;

  constructor(
    private firebase: FirebaseService,
    private reportService: ReportService,
    private toast: ToastService,
    private router: Router
  ) {}

  ngAfterViewInit(): void {
    this.initMap();
  }

  issueTypeLabel(type: IssueType): string {
    return ISSUE_TYPE_LABELS[type] ?? type;
  }

  onDragOver(e: DragEvent): void {
    e.preventDefault();
    this.dragOver.set(true);
  }

  onDrop(e: DragEvent): void {
    e.preventDefault();
    this.dragOver.set(false);
    const file = e.dataTransfer?.files?.[0];
    if (file?.type.startsWith('image/')) {
      this.setFile(file);
    }
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (file) this.setFile(file);
  }

  private setFile(file: File): void {
    this.selectedFile.set(file);
    const url = URL.createObjectURL(file);
    this.previewUrl.set(url);
  }

  private initMap(): void {
    const el = document.getElementById('report-map');
    if (!el || typeof google === 'undefined' || !google.maps) {
      this.setDefaultCoords();
      return;
    }
    const defaultCenter = { lat: 37.7749, lng: -122.4194 };
    this.map = new google.maps.Map(el, {
      center: defaultCenter,
      zoom: 14,
      mapTypeControl: true,
      fullscreenControl: true,
    });
    this.lat.set(defaultCenter.lat);
    this.lng.set(defaultCenter.lng);
    this.marker = new google.maps.Marker({
      position: defaultCenter,
      map: this.map,
      draggable: true,
    });
    this.map.addListener('click', (e: google.maps.MapMouseEvent) => {
      const pos = e.latLng;
      if (pos) {
        this.lat.set(pos.lat());
        this.lng.set(pos.lng());
        this.marker?.setPosition(pos);
      }
    });
    this.marker.addListener('dragend', () => {
      const pos = this.marker!.getPosition();
      if (pos) {
        this.lat.set(pos.lat());
        this.lng.set(pos.lng());
      }
    });
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          const center = { lat: pos.coords.latitude, lng: pos.coords.longitude };
          this.lat.set(center.lat);
          this.lng.set(center.lng);
          this.map?.setCenter(center);
          this.marker?.setPosition(center);
        },
        () => {}
      );
    }
  }

  private setDefaultCoords(): void {
    this.lat.set(37.7749);
    this.lng.set(-122.4194);
  }

  async submit(stepper: MatStepper): Promise<void> {
    const file = this.selectedFile();
    const latitude = this.lat();
    const longitude = this.lng();
    if (!file || latitude == null || longitude == null) {
      this.toast.error('Please complete photo and location steps.');
      return;
    }
    this.submitting.set(true);
    try {
      const imageUrl = await this.firebase.uploadReportImage(file);
      const { reportId } = await this.reportService.submitReport({
        imageUrl,
        lat: latitude,
        lng: longitude,
        userDescription: this.userDescription || undefined,
      });
      this.createdReportId.set(reportId);
      this.submitted.set(true);
      this.submitting.set(false);
      this.analyzing.set(true);
      const analysis = await this.reportService.runAnalysis(reportId, imageUrl, this.userDescription || undefined);
      this.analyzing.set(false);
      if (analysis) {
        this.reportResult.set(analysis);
        this.toast.success('Report submitted and analyzed.');
      } else {
        this.reportResult.set({
          issueType: 'other',
          severity: 'Medium',
          aiSummary: 'Analysis could not be completed. A staff member will review manually.',
        });
        this.toast.info('Report submitted. AI analysis was unavailable; it will be reviewed manually.');
      }
    } catch (e) {
      this.submitting.set(false);
      this.toast.error('Failed to submit report. Please try again.');
    }
  }

  goToReport(): void {
    const id = this.createdReportId();
    if (id) this.router.navigate(['/report', id]);
  }
}

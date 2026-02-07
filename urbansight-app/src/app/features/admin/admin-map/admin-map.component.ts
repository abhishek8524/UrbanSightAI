import { Component, OnInit, OnDestroy, signal, inject } from '@angular/core';
import { Router } from '@angular/router';
import { ReportService } from '../../../core/services/report.service';
import { Report, Severity } from '../../../models/report.model';

@Component({
  selector: 'app-admin-map',
  standalone: true,
  imports: [],
  template: `
    <div class="admin-map-page">
      <div class="header">
        <h1>Admin map</h1>
        <p>Color-coded by severity: High (red), Medium (amber), Low (green).</p>
      </div>
      <div id="admin-map" class="map-container"></div>
      @if (loading()) {
        <div class="loading-overlay">
          <p>Loading reports…</p>
        </div>
      }
    </div>
  `,
  styles: [
    `
      .admin-map-page {
        position: relative;
        padding: 1rem;
        max-width: 1400px;
        margin: 0 auto;
      }
      .header {
        margin-bottom: 1rem;
      }
      .header h1 {
        font-size: 1.5rem;
        margin: 0 0 0.25rem;
      }
      .header p {
        margin: 0;
        color: #546e7a;
        font-size: 0.9rem;
      }
      .map-container {
        height: 70vh;
        min-height: 450px;
        border-radius: 12px;
        overflow: hidden;
        box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
      }
      .loading-overlay {
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(255, 255, 255, 0.8);
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: 12px;
      }
    `,
  ],
})
export class AdminMapComponent implements OnInit, OnDestroy {
  private reportService = inject(ReportService);
  private router = inject(Router);
  loading = signal(true);
  private map: google.maps.Map | null = null;
  private markers: google.maps.Marker[] = [];

  private severityColor(s: Severity): string {
    if (s === 'High') return '#c62828';
    if (s === 'Medium') return '#f57c00';
    return '#2e7d32';
  }

  ngOnInit(): void {
    this.reportService.getAdminPriorityReports().then((list) => {
      this.loading.set(false);
      this.initMap(list);
    });
  }

  ngOnDestroy(): void {
    this.markers.forEach((m) => m.setMap(null));
    this.markers = [];
  }

  private initMap(reports: Report[]): void {
    const el = document.getElementById('admin-map');
    if (!el) return;
    if (typeof google === 'undefined' || !google.maps) return;
    const center = reports.length
      ? { lat: reports[0].lat, lng: reports[0].lng }
      : { lat: 37.7749, lng: -122.4194 };
    this.map = new google.maps.Map(el, {
      center,
      zoom: 12,
      mapTypeControl: true,
      fullscreenControl: true,
    });
    reports.forEach((r) => {
      const color = this.severityColor(r.severity);
      const marker = new google.maps.Marker({
        position: { lat: r.lat, lng: r.lng },
        map: this.map!,
        icon: {
          path: google.maps.SymbolPath.CIRCLE,
          scale: 12,
          fillColor: color,
          fillOpacity: 1,
          strokeColor: '#fff',
          strokeWeight: 2,
        },
        title: `${r.severity}: ${(r.aiSummary || '').slice(0, 60)}`,
      });
      if (r.id) {
        marker.addListener('click', () => {
          this.router.navigate(['/admin/report', r.id]);
        });
      }
      this.markers.push(marker);
    });
    if (reports.length > 1) {
      const bounds = new google.maps.LatLngBounds();
      reports.forEach((r) => bounds.extend({ lat: r.lat, lng: r.lng }));
      this.map.fitBounds(bounds);
    }
  }
}

import { Component, OnInit, OnDestroy, signal, inject } from '@angular/core';
import { ReportService } from '../../../core/services/report.service';
import { Report } from '../../../models/report.model';

@Component({
  selector: 'app-public-map',
  standalone: true,
  imports: [],
  template: `
    <div class="map-page">
      <div class="header">
        <h1>City reports map</h1>
        <p>Click a marker to see details.</p>
      </div>
      <div id="public-map" class="map-container"></div>
      @if (loading()) {
        <div class="loading-overlay">
          <p>Loading reports…</p>
        </div>
      }
    </div>
  `,
  styles: [
    `
      .map-page {
        position: relative;
        padding: 1rem;
        max-width: 1200px;
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
        height: 60vh;
        min-height: 400px;
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
export class PublicMapComponent implements OnInit, OnDestroy {
  private reportService = inject(ReportService);
  loading = signal(true);
  private map: google.maps.Map | null = null;
  private markers: google.maps.Marker[] = [];

  ngOnInit(): void {
    this.loadReports();
  }

  ngOnDestroy(): void {
    this.markers.forEach((m) => m.setMap(null));
    this.markers = [];
  }

  private async loadReports(): Promise<void> {
    try {
      const reports = await this.reportService.loadReportsForMap();
      this.loading.set(false);
      this.initMap(reports);
    } catch {
      this.loading.set(false);
    }
  }

  private initMap(reports: Report[]): void {
    const el = document.getElementById('public-map');
    if (!el) return;
    if (typeof google === 'undefined' || !google.maps) {
      return;
    }
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
      const marker = new google.maps.Marker({
        position: { lat: r.lat, lng: r.lng },
        map: this.map!,
        title: r.aiSummary?.slice(0, 80) || 'Report',
      });
      if (r.id) {
        marker.addListener('click', () => {
          window.location.href = `/report/${r.id}`;
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

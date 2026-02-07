import { Component } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';

@Component({
  selector: 'app-main-layout',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive, MatToolbarModule, MatButtonModule],
  template: `
    <mat-toolbar color="primary" class="main-toolbar">
      <a mat-button routerLink="/" class="brand">Urbansight</a>
      <span class="spacer"></span>
      <a mat-button routerLink="/" routerLinkActive="active" [routerLinkActiveOptions]="{ exact: true }">Home</a>
      <a mat-button routerLink="/report" routerLinkActive="active">Report</a>
      <a mat-button routerLink="/map" routerLinkActive="active">Map</a>
      <a mat-button routerLink="/admin/dashboard" routerLinkActive="active">Admin</a>
    </mat-toolbar>
    <main class="main-content">
      <router-outlet></router-outlet>
    </main>
  `,
  styles: [
    `
      .main-toolbar {
        position: sticky;
        top: 0;
        z-index: 100;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
      }
      .brand {
        font-size: 1.35rem;
        font-weight: 600;
        letter-spacing: -0.02em;
      }
      .spacer {
        flex: 1;
      }
      .main-toolbar a.active {
        font-weight: 600;
        background: rgba(255, 255, 255, 0.15);
      }
      .main-content {
        min-height: calc(100vh - 64px);
      }
    `,
  ],
})
export class MainLayoutComponent {}
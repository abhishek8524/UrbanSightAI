import { Routes } from '@angular/router';
import { MainLayoutComponent } from './layout/main-layout/main-layout.component';

export const routes: Routes = [
  {
    path: '',
    component: MainLayoutComponent,
    children: [
      { path: '', loadComponent: () => import('./features/landing/landing.component').then((m) => m.LandingComponent) },
      { path: 'report', loadComponent: () => import('./features/report/report-wizard/report-wizard.component').then((m) => m.ReportWizardComponent) },
      { path: 'map', loadComponent: () => import('./features/map/public-map/public-map.component').then((m) => m.PublicMapComponent) },
      { path: 'report/:id', loadComponent: () => import('./features/report/report-detail/report-detail.component').then((m) => m.ReportDetailComponent) },
      { path: 'admin/dashboard', loadComponent: () => import('./features/admin/admin-dashboard/admin-dashboard.component').then((m) => m.AdminDashboardComponent) },
      { path: 'admin/map', loadComponent: () => import('./features/admin/admin-map/admin-map.component').then((m) => m.AdminMapComponent) },
      { path: 'admin/report/:id', loadComponent: () => import('./features/admin/admin-report-detail/admin-report-detail.component').then((m) => m.AdminReportDetailComponent) },
    ],
  },
  { path: '**', redirectTo: '' },
];

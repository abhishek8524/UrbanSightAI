import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';

@Component({
  selector: 'app-landing',
  standalone: true,
  imports: [RouterLink, MatButtonModule, MatCardModule],
  template: `
    <section class="hero">
      <div class="hero-content">
        <h1>Urbansight</h1>
        <p class="tagline">Smart reporting for sustainable cities</p>
        <p class="sub">Report infrastructure issues in your community. AI-powered triage helps city staff prioritize and act faster.</p>
        <div class="cta">
          <a mat-raised-button color="primary" routerLink="/report" class="cta-primary">Report an issue</a>
          <a mat-stroked-button routerLink="/map">View map</a>
        </div>
      </div>
    </section>
    <section class="features">
      <h2>How it works</h2>
      <div class="feature-cards">
        <mat-card class="feature-card">
          <mat-card-header>
            <mat-card-title>1. Report</mat-card-title>
          </mat-card-header>
          <mat-card-content>
            Upload a photo and pin the location. Add an optional description.
          </mat-card-content>
        </mat-card>
        <mat-card class="feature-card">
          <mat-card-header>
            <mat-card-title>2. AI analysis</mat-card-title>
          </mat-card-header>
          <mat-card-content>
            Gemini Vision classifies the issue, assesses severity, and generates an action-ready summary.
          </mat-card-content>
        </mat-card>
        <mat-card class="feature-card">
          <mat-card-header>
            <mat-card-title>3. Priority queue</mat-card-title>
          </mat-card-header>
          <mat-card-content>
            City staff see a prioritized list and map to resolve issues efficiently.
          </mat-card-content>
        </mat-card>
      </div>
    </section>
    <section class="sdg">
      <mat-card class="sdg-card">
        <mat-card-content>
          <h3>SDG 11: Sustainable Cities & Communities</h3>
          <p>
            Urbansight supports making cities inclusive, safe, resilient, and sustainable by enabling citizens to report and triage infrastructure issues—from potholes and flooding to accessibility hazards—so communities can respond quickly and fairly.
          </p>
        </mat-card-content>
      </mat-card>
    </section>
  `,
  styles: [
    `
      .hero {
        background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 50%, var(--primary-light) 100%);
        color: white;
        padding: 4rem 2rem;
        text-align: center;
      }
      .hero-content {
        max-width: 640px;
        margin: 0 auto;
      }
      .hero h1 {
        font-size: 2.75rem;
        font-weight: 700;
        margin: 0 0 0.5rem;
        letter-spacing: -0.02em;
      }
      .tagline {
        font-size: 1.35rem;
        opacity: 0.95;
        margin: 0 0 1rem;
      }
      .sub {
        font-size: 1rem;
        opacity: 0.9;
        margin: 0 0 2rem;
        line-height: 1.5;
      }
      .cta {
        display: flex;
        gap: 1rem;
        justify-content: center;
        flex-wrap: wrap;
      }
      .cta a {
        min-width: 140px;
      }
      .cta-primary {
        background: white !important;
        color: var(--primary) !important;
      }
      .features {
        max-width: 960px;
        margin: 0 auto;
        padding: 3rem 2rem;
      }
      .features h2 {
        font-size: 1.75rem;
        font-weight: 600;
        margin: 0 0 2rem;
        text-align: center;
      }
      .feature-cards {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
        gap: 1.5rem;
      }
      .feature-card mat-card-title {
        font-size: 1.1rem;
      }
      .feature-card mat-card-content {
        color: rgba(0, 0, 0, 0.7);
        line-height: 1.5;
      }
      .sdg {
        max-width: 720px;
        margin: 0 auto;
        padding: 0 2rem 4rem;
      }
      .sdg-card {
        background: #f5f7fa;
      }
      .sdg h3 {
        font-size: 1.25rem;
        margin: 0 0 0.75rem;
      }
      .sdg p {
        margin: 0;
        line-height: 1.6;
        color: #374151;
      }
    `,
  ],
})
export class LandingComponent {}
import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-skeleton-loader',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="skeleton-container">
      <div class="skeleton-block skeleton-image"></div>
      <div class="skeleton-line skeleton-title"></div>
      <div class="skeleton-line skeleton-text"></div>
      <div class="skeleton-line skeleton-text short"></div>
    </div>
  `,
  styles: [
    `
      .skeleton-container {
        padding: 1rem;
      }
      .skeleton-block,
      .skeleton-line {
        background: linear-gradient(
          90deg,
          #e0e0e0 25%,
          #f0f0f0 50%,
          #e0e0e0 75%
        );
        background-size: 200% 100%;
        animation: shimmer 1.5s infinite;
        border-radius: 8px;
      }
      .skeleton-image {
        height: 200px;
        margin-bottom: 1rem;
      }
      .skeleton-title {
        height: 24px;
        width: 60%;
        margin-bottom: 0.75rem;
      }
      .skeleton-text {
        height: 16px;
        width: 100%;
        margin-bottom: 0.5rem;
      }
      .skeleton-text.short {
        width: 80%;
      }
      @keyframes shimmer {
        0% {
          background-position: 200% 0;
        }
        100% {
          background-position: -200% 0;
        }
      }
    `,
  ],
})
export class SkeletonLoaderComponent {}
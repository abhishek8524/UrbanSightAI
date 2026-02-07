export type IssueType =
  | 'pothole'
  | 'broken_streetlight'
  | 'flooding'
  | 'debris_garbage'
  | 'sidewalk_hazard'
  | 'other';

export type Severity = 'Low' | 'Medium' | 'High';

export type ReportStatus = 'New' | 'InReview' | 'Resolved';

export interface Report {
  id?: string;
  imageUrl: string;
  lat: number;
  lng: number;
  userDescription?: string;
  issueType: IssueType;
  severity: Severity;
  aiSummary: string;
  status: ReportStatus;
  createdAt: number; // Firestore timestamp as number
  upvotes: number;
}

export interface ReportCreate {
  imageUrl: string;
  lat: number;
  lng: number;
  userDescription?: string;
}

export interface GeminiAnalysisResult {
  issueType: IssueType;
  severity: Severity;
  aiSummary: string;
}

export const ISSUE_TYPE_LABELS: Record<IssueType, string> = {
  pothole: 'Pothole',
  broken_streetlight: 'Broken streetlight',
  flooding: 'Flooding',
  debris_garbage: 'Debris / garbage overflow',
  sidewalk_hazard: 'Sidewalk / accessibility hazard',
  other: 'Other',
};

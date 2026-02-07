import { Injectable } from '@angular/core';
import { initializeApp, FirebaseApp } from 'firebase/app';
import {
  getFirestore,
  Firestore,
  collection,
  doc,
  addDoc,
  getDoc,
  getDocs,
  updateDoc,
  query,
  orderBy,
  where,
  limit,
  Timestamp,
  writeBatch,
  DocumentReference,
} from 'firebase/firestore';
import { getStorage, ref, uploadBytes, getDownloadURL, FirebaseStorage } from 'firebase/storage';
import { getFunctions, httpsCallable, Functions } from 'firebase/functions';
import { environment } from '../../../environments/environment';
import { Report, ReportStatus } from '../../models/report.model';

@Injectable({ providedIn: 'root' })
export class FirebaseService {
  private app: FirebaseApp;
  private firestore: Firestore;
  private storage: FirebaseStorage;
  private functions: Functions;

  constructor() {
    this.app = initializeApp(environment.firebase);
    this.firestore = getFirestore(this.app);
    this.storage = getStorage(this.app);
    this.functions = getFunctions(this.app);
  }

  getFirestore(): Firestore {
    return this.firestore;
  }

  getStorage(): FirebaseStorage {
    return this.storage;
  }

  getFunctions(): Functions {
    return this.functions;
  }

  async uploadReportImage(file: File): Promise<string> {
    const path = `reports/${Date.now()}_${file.name}`;
    const storageRef = ref(this.storage, path);
    await uploadBytes(storageRef, file);
    return getDownloadURL(storageRef);
  }

  async createReport(data: Omit<Report, 'id' | 'createdAt'>): Promise<string> {
    const col = collection(this.firestore, 'reports');
    const docRef = await addDoc(col, {
      ...data,
      createdAt: Timestamp.now().toMillis(),
    });
    return docRef.id;
  }

  async getReport(id: string): Promise<Report | null> {
    const docRef = doc(this.firestore, 'reports', id);
    const snap = await getDoc(docRef);
    if (!snap.exists()) return null;
    return { id: snap.id, ...this.mapDoc(snap.data()) } as Report;
  }

  async getReports(limitCount = 100): Promise<Report[]> {
    const col = collection(this.firestore, 'reports');
    const q = query(
      col,
      orderBy('createdAt', 'desc'),
      limit(limitCount)
    );
    const snap = await getDocs(q);
    return snap.docs.map((d) => ({ id: d.id, ...this.mapDoc(d.data()) } as Report));
  }

  async getReportsForMap(): Promise<Report[]> {
    return this.getReports(500);
  }

  async updateReportStatus(id: string, status: ReportStatus): Promise<void> {
    const docRef = doc(this.firestore, 'reports', id);
    await updateDoc(docRef, { status });
  }

  async upvoteReport(id: string): Promise<void> {
    const docRef = doc(this.firestore, 'reports', id);
    const snap = await getDoc(docRef);
    if (!snap.exists()) return;
    const current = snap.data()['upvotes'] ?? 0;
    await updateDoc(docRef, { upvotes: current + 1 });
  }

  async triggerAnalyzeReport(reportId: string, imageUrl: string, userDescription?: string): Promise<unknown> {
    const fn = httpsCallable<{ reportId: string; imageUrl: string; userDescription?: string }>(this.functions, 'analyzeReport');
    return fn({ reportId, imageUrl, userDescription });
  }

  private mapDoc(data: Record<string, unknown>): Record<string, unknown> {
    const out = { ...data };
    if (data['createdAt'] && typeof (data['createdAt'] as { toMillis?: () => number }).toMillis === 'function') {
      out['createdAt'] = (data['createdAt'] as { toMillis: () => number }).toMillis();
    }
    return out;
  }
}

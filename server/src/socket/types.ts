export interface BufferedLocation {
  busId: string;
  lat: number;
  lng: number;
  speed: number;
  heading: number;
  timestamp: Date;
}

export interface ThrottledBroadcast {
  timeout: NodeJS.Timeout | null;
  lastEmitTime: number;
  latestData: any;
}

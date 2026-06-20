# Programmatic Google Maps API Usage Tracking Guide

This guide outlines how to integrate the official **Google Cloud Monitoring API** into the backend server to retrieve live, programmatically queried Google Maps Platform usage statistics instead of relying solely on local counters.

---

## 1. Prerequisites (GCP Setup)

To query usage statistics programmatically, you must configure authentication and permissions on Google Cloud Platform:

1.  **Enable the Cloud Monitoring API**:
    - Navigate to the GCP Console -> **APIs & Services** -> **Library**.
    - Search for **Cloud Monitoring API** and click **Enable**.
2.  **Create a Service Account**:
    - Go to **IAM & Admin** -> **Service Accounts** -> **Create Service Account**.
    - Name it (e.g., `maps-api-monitor`).
3.  **Assign Permissions (IAM Role)**:
    - Grant the service account the **Monitoring Viewer** role (`roles/monitoring.viewer`). This permission permits querying time-series metrics without editing any infrastructure.
4.  **Download JSON Key**:
    - Under the newly created Service Account, go to the **Keys** tab -> **Add Key** -> **Create new key** (JSON format).
    - Save this file securely as `gcp-credentials.json` on the server and add its path to your environment variables:
      ```env
      GOOGLE_APPLICATION_CREDENTIALS="./gcp-credentials.json"
      GCP_PROJECT_ID="your-gcp-project-id"
      ```

---

## 2. Server-Side Node.js Integration

### Install GCP Client SDK

Install the official Google Cloud Monitoring package in your `server` directory:

```bash
npm install @google-cloud/monitoring
```

### Querying Usage Stats (Implementation Example)

Create a service class (e.g., `GcpMetricsService.ts`) to query API request counts over a specific time window:

```typescript
import { MetricServiceClient } from "@google-cloud/monitoring";
import logger from "@/utils/logger";

const client = new MetricServiceClient();
const projectId = process.env.GCP_PROJECT_ID || "";

export interface GcpApiMetrics {
  directions: number;
  autocomplete: number;
  placeDetails: number;
  geocoding: number;
}

/**
 * Fetch request count metrics from Google Cloud Monitoring
 * @param windowInMinutes The duration back from now to count (default 24 hours = 1440 mins)
 */
export async function getGoogleApiStatsFromGcp(
  windowInMinutes: number = 1440,
): Promise<GcpApiMetrics> {
  const stats: GcpApiMetrics = {
    directions: 0,
    autocomplete: 0,
    placeDetails: 0,
    geocoding: 0,
  };

  if (!projectId) {
    logger.warn("[GCP Metrics] GCP_PROJECT_ID is not configured.");
    return stats;
  }

  const name = client.projectPath(projectId);
  const now = new Date();
  const startTime = new Date(now.getTime() - windowInMinutes * 60 * 1000);

  // We request request_count from serviceruntime
  const filter = `
    metric.type = "serviceruntime.googleapis.com/api/request_count" 
    AND resource.type = "api"
  `;

  try {
    const [timeSeries] = await client.listTimeSeries({
      name,
      filter,
      interval: {
        startTime: {
          seconds: Math.floor(startTime.getTime() / 1000),
        },
        endTime: {
          seconds: Math.floor(now.getTime() / 1000),
        },
      },
      // Aggregate requests per API service type
      aggregation: {
        alignmentPeriod: {
          seconds: windowInMinutes * 60,
        },
        perSeriesAligner: "ALIGN_SUM",
        crossSeriesReducer: "REDUCE_SUM",
        groupByFields: ["resource.label.service"],
      },
    });

    for (const series of timeSeries) {
      const serviceName = series.resource?.labels?.service || "";
      const points = series.points || [];
      const totalCount = points.reduce(
        (sum, p) => sum + Number(p.value?.int64Value || 0),
        0,
      );

      // Map GCP services to local dashboard names
      if (serviceName.includes("directions")) {
        stats.directions = totalCount;
      } else if (serviceName.includes("places")) {
        // Places API covers both autocomplete and place details
        // Note: For finer breakdown, filter/group by metric.label.method or refer to billing API.
        stats.autocomplete = totalCount;
      } else if (serviceName.includes("geocoding")) {
        stats.geocoding = totalCount;
      }
    }
  } catch (error) {
    logger.error("[GCP Metrics] Failed to query Cloud Monitoring:", error);
  }

  return stats;
}
```

---

## 3. Integrating with Super Admin Controller

In `superAdmin.controller.ts`, instead of querying local MongoDB config documents, you can call the GCP monitoring function directly to serve live, verified data:

```typescript
import { getGoogleApiStatsFromGcp } from "@/services/GcpMetricsService";

export const getStorageStats = async (req: Request, res: Response) => {
  try {
    // 1. Fetch GCP Statistics
    const gcpStats = await getGoogleApiStatsFromGcp(1440); // 24-hour window

    // 2. Fetch other stats (Mongo, Redis)
    const dbStats = await mongoose.connection.db.stats();

    res.json({
      mongodb: { ... },
      redis: { ... },
      googleApi: {
        total: gcpStats.directions + gcpStats.autocomplete + gcpStats.geocoding,
        directions: gcpStats.directions,
        autocomplete: gcpStats.autocomplete,
        placeDetails: gcpStats.placeDetails,
        geocoding: gcpStats.geocoding,
      },
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
```

Metric Delta Indicators & Trends: Build trend indicator badges (e.g. green/red percentage arrows) next to each API usage count in StorageAnalysis.jsx to show whether request rates are increasing or decreasing compared to previous periods.
Detailed Tooltips with API SKU Descriptions: Upgrade the chart tooltips in the React UI with contextual explanations of what each API SKU means (e.g., explaining that "Details" cost more than "Autocomplete") to educate administrators on cost implications directly inside the dashboard.
Chart Responsive Grid Breakpoints: Enhance the layout design of the System Analysis page by using responsive breakpoints (xl:grid-cols-3 grids) to display MongoDB, Redis, and Google API graphs in a visually balanced dashboard regardless of the admin's device resolution.

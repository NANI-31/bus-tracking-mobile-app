import { z } from "zod";

export const triggerSosSchema = z.object({
  body: z.object({
    busId: z.string().optional(),
    routeId: z.string().optional(),
    location: z.object({
      lat: z.number(),
      lng: z.number(),
    }),
  }),
});

export const resolveSosSchema = z.object({
  params: z.object({
    id: z.string().min(1, "SOS ID is required"),
  }),
  body: z.object({
    resolutionNotes: z.string().optional().nullable(),
  }),
});

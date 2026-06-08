import { z } from "zod";

export const addBusNumberSchema = z.object({
  body: z.object({
    collegeId: z.string().min(1, "College ID is required"),
    busNumber: z.string().min(1, "Bus Number is required"),
  }),
});

export const removeBusNumberSchema = z.object({
  params: z.object({
    collegeId: z.string().min(1, "College ID is required"),
    busNumber: z.string().min(1, "Bus Number is required"),
  }),
});

export const renameBusNumberSchema = z.object({
  body: z.object({
    collegeId: z.string().min(1, "College ID is required"),
    oldBusNumber: z.string().min(1, "Old Bus Number is required"),
    newBusNumber: z.string().min(1, "New Bus Number is required"),
  }),
});
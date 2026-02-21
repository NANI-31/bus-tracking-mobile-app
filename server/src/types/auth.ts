import { Request } from "express";

export interface IAuthRequest extends Request {
  user?: {
    id: string;
    email: string;
    role: string;
    fullName?: string;
    collegeId: any;
    isPremium: boolean;
    subscriptionPlan?: string;
  };
}

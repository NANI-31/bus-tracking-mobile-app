// src/utils/buildNotification.ts
import { getTemplatesForLanguage } from "../constants/notificationTemplates";
import { resolveTemplate } from "./templateResolver";

type LanguageCode = "en" | "hi" | "te";

export const buildNotificationMessage = (
  type: string,
  payload: Record<string, string | number>,
  language: LanguageCode = "en"
) => {
  const template = getTemplatesForLanguage(type, language);

  return {
    title: resolveTemplate(template.title, payload),
    message: resolveTemplate(template.body, payload),
  };
};

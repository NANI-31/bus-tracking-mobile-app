// src/utils/templateResolver.ts
export const resolveTemplate = (
  template: string,
  data: Record<string, string | number>
): string => {
  let result = template;

  for (const key in data) {
    result = result.replace(new RegExp(`{{${key}}}`, "g"), String(data[key]));
  }

  return result;
};

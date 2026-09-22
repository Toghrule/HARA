import { ContactType, SocialMediaPlatform, SubmissionStatus } from "../types";

export const contactTypeLabels: Record<ContactType, string> = {
  [ContactType.Phone]: "Phone",
  [ContactType.Email]: "Email",
};

export const socialPlatformLabels: Record<SocialMediaPlatform, string> = {
  [SocialMediaPlatform.Facebook]: "Facebook",
  [SocialMediaPlatform.Instagram]: "Instagram",
  [SocialMediaPlatform.X]: "X (Twitter)",
  [SocialMediaPlatform.TikTok]: "TikTok",
  [SocialMediaPlatform.YouTube]: "YouTube",
  [SocialMediaPlatform.LinkedIn]: "LinkedIn",
  [SocialMediaPlatform.Website]: "Website",
  [SocialMediaPlatform.Other]: "Other",
};

export const submissionStatusLabels: Record<SubmissionStatus, string> = {
  [SubmissionStatus.Pending]: "Pending",
  [SubmissionStatus.Approved]: "Approved",
  [SubmissionStatus.Rejected]: "Rejected",
};

export const submissionStatusBadgeVariant: Record<SubmissionStatus, "success" | "warning" | "danger"> = {
  [SubmissionStatus.Pending]: "warning",
  [SubmissionStatus.Approved]: "success",
  [SubmissionStatus.Rejected]: "danger",
};

export function numericEnumEntries(e: object): [string, number][] {
  return Object.entries(e).filter((entry): entry is [string, number] => typeof entry[1] === "number");
}

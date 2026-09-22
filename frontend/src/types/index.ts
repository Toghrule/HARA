// Enums — values must match the backend's C# enums exactly (they serialize as integers).

export enum SubmissionStatus {
  Pending = 0,
  Approved = 1,
  Rejected = 2,
}

export enum ContactType {
  Phone = 0,
  Email = 1,
}

export enum SocialMediaPlatform {
  Facebook = 0,
  Instagram = 1,
  X = 2,
  TikTok = 3,
  YouTube = 4,
  LinkedIn = 5,
  Website = 6,
  Other = 99,
}

// Auth

export interface LoginResult {
  token: string;
  expiresAtUtc: string;
}

// Restaurants

export interface RestaurantDto {
  id: string;
  name: string;
  description: string | null;
  address: string;
  latitude: number;
  longitude: number;
  phoneNumber: string | null;
  imageUrl: string | null;
  isActive: boolean;
  createdAt: string;
  lastModifiedAt: string | null;
}

export interface CreateRestaurantBody {
  name: string;
  description?: string | null;
  address: string;
  latitude: number;
  longitude: number;
  phoneNumber?: string | null;
  imageUrl?: string | null;
}

export interface UpdateRestaurantBody extends CreateRestaurantBody {
  isActive: boolean;
}

// Restaurant submissions

export interface RestaurantSubmissionDto {
  id: string;
  restaurantName: string;
  description: string | null;
  address: string | null;
  phoneNumber: string | null;
  submitterName: string;
  submitterEmail: string | null;
  submitterPhoneNumber: string | null;
  status: SubmissionStatus;
  adminNote: string | null;
  reviewedAt: string | null;
  createdAt: string;
}

export interface ReviewSubmissionBody {
  decision: SubmissionStatus;
  adminNote?: string | null;
}

// Advertisements

export interface AdvertisementDto {
  id: string;
  title: string | null;
  imageUrl: string;
  linkUrl: string | null;
  sortOrder: number;
  isActive: boolean;
  createdAt: string;
  lastModifiedAt: string | null;
}

export interface CreateAdvertisementBody {
  title?: string | null;
  imageUrl: string;
  linkUrl?: string | null;
  sortOrder: number;
}

export interface UpdateAdvertisementBody extends CreateAdvertisementBody {
  isActive: boolean;
}

// FAQ

export interface FaqItemDto {
  id: string;
  question: string;
  answer: string;
  sortOrder: number;
  isActive: boolean;
  createdAt: string;
  lastModifiedAt: string | null;
}

export interface CreateFaqItemBody {
  question: string;
  answer: string;
  sortOrder: number;
}

export interface UpdateFaqItemBody extends CreateFaqItemBody {
  isActive: boolean;
}

// Company info — About Us

export interface AboutUsDto {
  id: string;
  companyName: string;
  description: string;
  logoUrl: string | null;
  lastModifiedAt: string | null;
}

export interface UpdateAboutUsBody {
  companyName: string;
  description: string;
  logoUrl?: string | null;
}

// Company info — Contacts

export interface ContactInfoDto {
  id: string;
  type: ContactType;
  value: string;
  label: string | null;
  sortOrder: number;
  isActive: boolean;
}

export interface CreateContactInfoBody {
  type: ContactType;
  value: string;
  label?: string | null;
  sortOrder: number;
}

export interface UpdateContactInfoBody extends CreateContactInfoBody {
  isActive: boolean;
}

// Company info — Social links

export interface SocialMediaLinkDto {
  id: string;
  platform: SocialMediaPlatform;
  url: string;
  sortOrder: number;
  isActive: boolean;
}

export interface CreateSocialMediaLinkBody {
  platform: SocialMediaPlatform;
  url: string;
  sortOrder: number;
}

export interface UpdateSocialMediaLinkBody extends CreateSocialMediaLinkBody {
  isActive: boolean;
}

// Uploads

export interface UploadImageResult {
  url: string;
}

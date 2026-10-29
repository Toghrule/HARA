/** The kinds of cuisine a restaurant can be filed under: the codes the server accepts, with the names shown here. */
export const cuisineOptions = [
  { code: "azerbaijani", label: "Azerbaijani" },
  { code: "kebab", label: "Kebab and grill" },
  { code: "european", label: "European" },
  { code: "italian", label: "Italian" },
  { code: "turkish", label: "Turkish" },
  { code: "georgian", label: "Georgian" },
  { code: "asian", label: "Asian" },
  { code: "seafood", label: "Seafood" },
  { code: "fastfood", label: "Fast food" },
  { code: "pizza", label: "Pizza" },
  { code: "cafe", label: "Cafe" },
  { code: "dessert", label: "Desserts" },
] as const;

/** The most cuisines one restaurant can have. */
export const maxCuisines = 3;

/** The most photos one restaurant can have. */
export const maxGalleryPhotos = 10;

export interface CoordinatePair {
  latitude: number;
  longitude: number;
}

// Google Maps' "degrees, minutes, seconds" text, e.g.  40°23'29.1"N 49°57'12.7"E
const DMS_PAIR =
  /(\d{1,3})\s*°\s*(\d{1,2})\s*['′’]\s*(\d{1,2}(?:\.\d+)?)\s*(?:["″”]|'')?\s*([NSns])\s*[,;]?\s*(\d{1,3})\s*°\s*(\d{1,2})\s*['′’]\s*(\d{1,2}(?:\.\d+)?)\s*(?:["″”]|'')?\s*([EWew])/;

const DECIMAL_NUMBER = /^-?\d+(?:\.\d+)?$/;

function dmsToDecimal(degrees: string, minutes: string, seconds: string, hemisphere: string): number | null {
  const min = Number(minutes);
  const sec = Number(seconds);
  if (min >= 60 || sec >= 60) return null;

  const value = Number(degrees) + min / 60 + sec / 3600;
  return /[SsWw]/.test(hemisphere) ? -value : value;
}

function toCoordinatePair(latitude: number, longitude: number): CoordinatePair | null {
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return null;
  if (Math.abs(latitude) > 90 || Math.abs(longitude) > 180) return null;

  // Six decimals is what the backend stores (about 10 cm).
  return { latitude: Number(latitude.toFixed(6)), longitude: Number(longitude.toFixed(6)) };
}

/**
 * Reads a latitude/longitude pair out of text copied from Google Maps: either decimal degrees
 * ("40.4093, 49.8671") or degrees-minutes-seconds ("40°23'29.1"N 49°57'12.7"E").
 * Returns null for anything else, so ordinary text (a single number, say) is left alone.
 */
export function parseCoordinatePair(text: string): CoordinatePair | null {
  const dms = DMS_PAIR.exec(text);
  if (dms) {
    const latitude = dmsToDecimal(dms[1], dms[2], dms[3], dms[4]);
    const longitude = dmsToDecimal(dms[5], dms[6], dms[7], dms[8]);
    return latitude === null || longitude === null ? null : toCoordinatePair(latitude, longitude);
  }

  const tokens = text.trim().split(/[\s,;]+/).filter(Boolean);
  if (tokens.length === 2 && tokens.every((token) => DECIMAL_NUMBER.test(token))) {
    return toCoordinatePair(Number(tokens[0]), Number(tokens[1]));
  }

  return null;
}

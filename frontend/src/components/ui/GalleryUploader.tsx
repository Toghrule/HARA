import { useState, type ChangeEvent } from "react";
import { ArrowLeft, ArrowRight, X } from "lucide-react";
import { api, ApiError, resolveAssetUrl } from "../../lib/api";
import { useToast } from "./Toast";
import type { UploadImageResult } from "../../types";

interface GalleryUploaderProps {
  category: string;
  value: string[];
  onChange: (urls: string[]) => void;
  max: number;
}

/** A row of photos the admin can add to, remove from and put in order. The first one is shown first in the app. */
export function GalleryUploader({ category, value, onChange, max }: GalleryUploaderProps) {
  const [isUploading, setIsUploading] = useState(false);
  const { push } = useToast();

  const handleFilesChange = async (event: ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(event.target.files ?? []);
    event.target.value = "";
    if (files.length === 0) return;

    const room = max - value.length;
    if (files.length > room) {
      push(`Only ${max} photos fit. ${room > 0 ? `The first ${room} will be added.` : "Remove one first."}`, "error");
    }

    setIsUploading(true);
    const added: string[] = [];
    try {
      // One after the other, so a failure stops at a clear point and the order stays the order chosen.
      for (const file of files.slice(0, Math.max(room, 0))) {
        const formData = new FormData();
        formData.append("file", file);
        const result = await api.upload<UploadImageResult>(`/api/admin/uploads/${category}`, formData);
        added.push(result.url);
      }
    } catch (err) {
      push(err instanceof ApiError ? err.message : "Upload failed", "error");
    } finally {
      setIsUploading(false);
      if (added.length > 0) onChange([...value, ...added]);
    }
  };

  const move = (index: number, by: -1 | 1) => {
    const target = index + by;
    if (target < 0 || target >= value.length) return;
    const next = [...value];
    [next[index], next[target]] = [next[target], next[index]];
    onChange(next);
  };

  return (
    <div className="space-y-2">
      {value.length > 0 && (
        <ul className="flex flex-wrap gap-3" data-testid="gallery-list">
          {value.map((url, index) => (
            <li key={url} className="w-24 space-y-1">
              <img src={resolveAssetUrl(url) ?? ""} alt="" className="h-24 w-24 rounded-md border border-slate-200 object-cover" />
              <div className="flex items-center justify-between">
                <button
                  type="button"
                  aria-label="Move earlier"
                  disabled={index === 0}
                  onClick={() => move(index, -1)}
                  className="rounded p-1 text-slate-500 hover:bg-slate-100 disabled:opacity-30"
                >
                  <ArrowLeft className="h-3.5 w-3.5" />
                </button>
                <button
                  type="button"
                  aria-label="Remove photo"
                  onClick={() => onChange(value.filter((_, i) => i !== index))}
                  className="rounded p-1 text-red-600 hover:bg-red-50"
                >
                  <X className="h-3.5 w-3.5" />
                </button>
                <button
                  type="button"
                  aria-label="Move later"
                  disabled={index === value.length - 1}
                  onClick={() => move(index, 1)}
                  className="rounded p-1 text-slate-500 hover:bg-slate-100 disabled:opacity-30"
                >
                  <ArrowRight className="h-3.5 w-3.5" />
                </button>
              </div>
            </li>
          ))}
        </ul>
      )}
      {value.length < max && (
        <input
          type="file"
          multiple
          accept="image/jpeg,image/png,image/webp,image/gif"
          onChange={handleFilesChange}
          disabled={isUploading}
          className="block text-sm text-slate-600 file:mr-3 file:rounded-md file:border-0 file:bg-slate-900 file:px-3 file:py-1.5 file:text-sm file:text-white hover:file:bg-slate-800"
        />
      )}
      <p className="text-xs text-slate-400">
        {isUploading ? "Uploading…" : `${value.length} of ${max} photos. The first photo is shown first in the app.`}
      </p>
    </div>
  );
}

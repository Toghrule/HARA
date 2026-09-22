import { useState, type ChangeEvent } from "react";
import { api, ApiError, resolveAssetUrl } from "../../lib/api";
import { useToast } from "./Toast";
import type { UploadImageResult } from "../../types";

interface ImageUploaderProps {
  category: string;
  value: string | null | undefined;
  onChange: (url: string) => void;
}

export function ImageUploader({ category, value, onChange }: ImageUploaderProps) {
  const [isUploading, setIsUploading] = useState(false);
  const { push } = useToast();
  const previewSrc = resolveAssetUrl(value);

  const handleFileChange = async (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    event.target.value = "";
    if (!file) return;

    setIsUploading(true);
    try {
      const formData = new FormData();
      formData.append("file", file);
      const result = await api.upload<UploadImageResult>(`/api/admin/uploads/${category}`, formData);
      onChange(result.url);
    } catch (err) {
      push(err instanceof ApiError ? err.message : "Upload failed", "error");
    } finally {
      setIsUploading(false);
    }
  };

  return (
    <div className="space-y-2">
      {previewSrc && (
        <img src={previewSrc} alt="" className="h-24 w-24 rounded-md border border-slate-200 object-cover" />
      )}
      <input
        type="file"
        accept="image/jpeg,image/png,image/webp,image/gif"
        onChange={handleFileChange}
        disabled={isUploading}
        className="block text-sm text-slate-600 file:mr-3 file:rounded-md file:border-0 file:bg-slate-900 file:px-3 file:py-1.5 file:text-sm file:text-white hover:file:bg-slate-800"
      />
      {isUploading && <p className="text-xs text-slate-400">Uploading…</p>}
    </div>
  );
}

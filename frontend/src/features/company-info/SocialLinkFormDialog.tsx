import { useEffect } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Dialog } from "../../components/ui/Dialog";
import { Button } from "../../components/ui/Button";
import { Input } from "../../components/ui/Input";
import { Select } from "../../components/ui/Select";
import { Checkbox } from "../../components/ui/Checkbox";
import { FormField } from "../../components/ui/FormField";
import { useToast } from "../../components/ui/Toast";
import { ApiError } from "../../lib/api";
import { numericEnumEntries, socialPlatformLabels } from "../../lib/enumLabels";
import { useCreateSocialLink, useUpdateSocialLink } from "./socialLinksApi";
import { SocialMediaPlatform } from "../../types";
import type { SocialMediaLinkDto } from "../../types";

const schema = z.object({
  platform: z.coerce.number().int() as unknown as z.ZodType<SocialMediaPlatform>,
  url: z.string().trim().min(1, "URL is required").max(1000),
  isActive: z.boolean(),
});

type FormValues = z.infer<typeof schema>;

const emptyValues: FormValues = { platform: SocialMediaPlatform.Website, url: "", isActive: true };

interface SocialLinkFormDialogProps {
  open: boolean;
  onClose: () => void;
  link?: SocialMediaLinkDto | null;
  nextSortOrder: number;
}

export function SocialLinkFormDialog({ open, onClose, link, nextSortOrder }: SocialLinkFormDialogProps) {
  const isEdit = Boolean(link);
  const { push } = useToast();
  const createMutation = useCreateSocialLink();
  const updateMutation = useUpdateSocialLink();

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({ resolver: zodResolver(schema), defaultValues: emptyValues });

  useEffect(() => {
    if (!open) return;
    reset(link ? { platform: link.platform, url: link.url, isActive: link.isActive } : emptyValues);
  }, [open, link, reset]);

  const onSubmit = async (values: FormValues) => {
    try {
      if (isEdit && link) {
        await updateMutation.mutateAsync({
          id: link.id,
          body: { platform: values.platform, url: values.url, sortOrder: link.sortOrder, isActive: values.isActive },
        });
        push("Social link updated");
      } else {
        await createMutation.mutateAsync({ platform: values.platform, url: values.url, sortOrder: nextSortOrder });
        push("Social link created");
      }
      onClose();
    } catch (err) {
      push(err instanceof ApiError ? err.message : "Something went wrong", "error");
    }
  };

  return (
    <Dialog open={open} onClose={onClose} title={isEdit ? "Edit social link" : "Add social link"}>
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <FormField label="Platform" htmlFor="platform" error={errors.platform?.message}>
          <Select id="platform" {...register("platform", { valueAsNumber: true })}>
            {numericEnumEntries(SocialMediaPlatform).map(([key, value]) => (
              <option key={key} value={value}>
                {socialPlatformLabels[value as SocialMediaPlatform]}
              </option>
            ))}
          </Select>
        </FormField>
        <FormField label="URL" htmlFor="url" error={errors.url?.message}>
          <Input id="url" placeholder="https://…" {...register("url")} />
        </FormField>
        {isEdit && <Checkbox label="Active (shown in the mobile app)" {...register("isActive")} />}
        <div className="flex justify-end gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" disabled={isSubmitting}>
            {isEdit ? "Save changes" : "Create link"}
          </Button>
        </div>
      </form>
    </Dialog>
  );
}

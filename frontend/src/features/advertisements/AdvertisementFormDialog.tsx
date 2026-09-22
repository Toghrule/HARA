import { useEffect } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Dialog } from "../../components/ui/Dialog";
import { Button } from "../../components/ui/Button";
import { Input } from "../../components/ui/Input";
import { Checkbox } from "../../components/ui/Checkbox";
import { FormField } from "../../components/ui/FormField";
import { ImageUploader } from "../../components/ui/ImageUploader";
import { useToast } from "../../components/ui/Toast";
import { ApiError } from "../../lib/api";
import { useCreateAdvertisement, useUpdateAdvertisement } from "./api";
import type { AdvertisementDto } from "../../types";

const schema = z.object({
  title: z.string().trim().max(200).optional(),
  imageUrl: z.string().trim().min(1, "An image is required").max(1000),
  linkUrl: z.string().trim().max(1000).optional(),
  isActive: z.boolean(),
});

type FormValues = z.infer<typeof schema>;

const emptyValues: FormValues = { title: "", imageUrl: "", linkUrl: "", isActive: true };

interface AdvertisementFormDialogProps {
  open: boolean;
  onClose: () => void;
  advertisement?: AdvertisementDto | null;
  nextSortOrder: number;
}

export function AdvertisementFormDialog({
  open,
  onClose,
  advertisement,
  nextSortOrder,
}: AdvertisementFormDialogProps) {
  const isEdit = Boolean(advertisement);
  const { push } = useToast();
  const createMutation = useCreateAdvertisement();
  const updateMutation = useUpdateAdvertisement();

  const {
    register,
    handleSubmit,
    reset,
    setValue,
    watch,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({ resolver: zodResolver(schema), defaultValues: emptyValues });

  useEffect(() => {
    if (!open) return;
    reset(
      advertisement
        ? {
            title: advertisement.title ?? "",
            imageUrl: advertisement.imageUrl,
            linkUrl: advertisement.linkUrl ?? "",
            isActive: advertisement.isActive,
          }
        : emptyValues
    );
  }, [open, advertisement, reset]);

  const imageUrl = watch("imageUrl");

  const onSubmit = async (values: FormValues) => {
    const payload = {
      title: values.title || null,
      imageUrl: values.imageUrl,
      linkUrl: values.linkUrl || null,
    };
    try {
      if (isEdit && advertisement) {
        await updateMutation.mutateAsync({
          id: advertisement.id,
          body: { ...payload, sortOrder: advertisement.sortOrder, isActive: values.isActive },
        });
        push("Advertisement updated");
      } else {
        await createMutation.mutateAsync({ ...payload, sortOrder: nextSortOrder });
        push("Advertisement created");
      }
      onClose();
    } catch (err) {
      push(err instanceof ApiError ? err.message : "Something went wrong", "error");
    }
  };

  return (
    <Dialog open={open} onClose={onClose} title={isEdit ? "Edit advertisement" : "Add advertisement"}>
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <FormField label="Title" htmlFor="title" error={errors.title?.message}>
          <Input id="title" {...register("title")} />
        </FormField>
        <FormField label="Link URL" htmlFor="linkUrl" error={errors.linkUrl?.message}>
          <Input id="linkUrl" placeholder="https://…" {...register("linkUrl")} />
        </FormField>
        <FormField label="Image" error={errors.imageUrl?.message}>
          <ImageUploader
            category="advertisements"
            value={imageUrl}
            onChange={(url) => setValue("imageUrl", url, { shouldDirty: true, shouldValidate: true })}
          />
        </FormField>
        {isEdit && <Checkbox label="Active (shown in the mobile app carousel)" {...register("isActive")} />}
        <div className="flex justify-end gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" disabled={isSubmitting}>
            {isEdit ? "Save changes" : "Create advertisement"}
          </Button>
        </div>
      </form>
    </Dialog>
  );
}

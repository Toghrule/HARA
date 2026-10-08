import { useEffect, type ClipboardEvent } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Dialog } from "../../components/ui/Dialog";
import { Button } from "../../components/ui/Button";
import { Input } from "../../components/ui/Input";
import { Textarea } from "../../components/ui/Textarea";
import { Checkbox } from "../../components/ui/Checkbox";
import { FormField } from "../../components/ui/FormField";
import { ImageUploader } from "../../components/ui/ImageUploader";
import { useToast } from "../../components/ui/Toast";
import { ApiError } from "../../lib/api";
import { parseCoordinatePair } from "../../lib/coordinates";
import { useCreateRestaurant, useUpdateRestaurant } from "./api";
import type { RestaurantDto } from "../../types";

const schema = z.object({
  name: z.string().trim().min(1, "Name is required").max(200),
  description: z.string().trim().max(4000).optional(),
  descriptionRu: z.string().trim().max(4000).optional(),
  descriptionEn: z.string().trim().max(4000).optional(),
  address: z.string().trim().min(1, "Address is required").max(400),
  latitude: z.coerce.number({ invalid_type_error: "Latitude is required" }).min(-90, "Must be between -90 and 90").max(90, "Must be between -90 and 90"),
  longitude: z.coerce.number({ invalid_type_error: "Longitude is required" }).min(-180, "Must be between -180 and 180").max(180, "Must be between -180 and 180"),
  phoneNumber: z.string().trim().max(50).optional(),
  imageUrl: z.string().trim().max(1000).optional(),
  discountPercent: z.coerce
    .number({ invalid_type_error: "Discount is required" })
    .int("Must be a whole number")
    .min(0, "Must be between 0 and 100")
    .max(100, "Must be between 0 and 100"),
  isActive: z.boolean(),
});

type FormValues = z.infer<typeof schema>;

const emptyValues: FormValues = {
  name: "",
  description: "",
  descriptionRu: "",
  descriptionEn: "",
  address: "",
  latitude: 0,
  longitude: 0,
  phoneNumber: "",
  imageUrl: "",
  discountPercent: 0,
  isActive: true,
};

/** Starting values for a new restaurant, e.g. taken from an approved submission. */
export interface RestaurantPrefill {
  name?: string;
  address?: string;
  phoneNumber?: string;
  description?: string;
}

interface RestaurantFormDialogProps {
  open: boolean;
  onClose: () => void;
  restaurant?: RestaurantDto | null;
  /** Only used when creating. Keep the object stable between renders or the form resets while typing. */
  prefill?: RestaurantPrefill | null;
  /** Only used when creating. The registration this restaurant comes from: approves it and, if an owner signed up with it, makes them the restaurant's owner. */
  fromSubmissionId?: string | null;
}

export function RestaurantFormDialog({ open, onClose, restaurant, prefill, fromSubmissionId }: RestaurantFormDialogProps) {
  const isEdit = Boolean(restaurant);
  const { push } = useToast();
  const queryClient = useQueryClient();
  const createMutation = useCreateRestaurant();
  const updateMutation = useUpdateRestaurant();

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
      restaurant
        ? {
            name: restaurant.name,
            description: restaurant.description ?? "",
            descriptionRu: restaurant.descriptionRu ?? "",
            descriptionEn: restaurant.descriptionEn ?? "",
            address: restaurant.address,
            latitude: restaurant.latitude,
            longitude: restaurant.longitude,
            phoneNumber: restaurant.phoneNumber ?? "",
            imageUrl: restaurant.imageUrl ?? "",
            discountPercent: restaurant.discountPercent,
            isActive: restaurant.isActive,
          }
        : {
            ...emptyValues,
            name: prefill?.name ?? "",
            address: prefill?.address ?? "",
            phoneNumber: prefill?.phoneNumber ?? "",
            description: prefill?.description ?? "",
          }
    );
  }, [open, restaurant, prefill, reset]);

  const imageUrl = watch("imageUrl");
  const latitude = watch("latitude");
  const longitude = watch("longitude");
  const hasValidCoordinates = !Number.isNaN(latitude) && !Number.isNaN(longitude) && !(latitude === 0 && longitude === 0);

  // A number input drops everything but digits, so a pasted "40°23'29.1"N 49°57'12.7"E" or
  // "40.4093, 49.8671" would turn into garbage. Recognise those and fill both fields instead.
  const handleCoordinatePaste = (event: ClipboardEvent<HTMLInputElement>) => {
    const pair = parseCoordinatePair(event.clipboardData.getData("text"));
    if (!pair) return;

    event.preventDefault();
    setValue("latitude", pair.latitude, { shouldDirty: true, shouldValidate: true });
    setValue("longitude", pair.longitude, { shouldDirty: true, shouldValidate: true });
  };

  const onSubmit = async (values: FormValues) => {
    const payload = {
      name: values.name,
      description: values.description || null,
      descriptionRu: values.descriptionRu || null,
      descriptionEn: values.descriptionEn || null,
      address: values.address,
      latitude: values.latitude,
      longitude: values.longitude,
      phoneNumber: values.phoneNumber || null,
      imageUrl: values.imageUrl || null,
      discountPercent: values.discountPercent,
    };
    try {
      if (isEdit && restaurant) {
        await updateMutation.mutateAsync({ id: restaurant.id, body: { ...payload, isActive: values.isActive } });
        push("Restaurant updated");
      } else {
        await createMutation.mutateAsync({ ...payload, fromSubmissionId: fromSubmissionId ?? null });
        if (fromSubmissionId) {
          // The registration is now approved and linked to this restaurant.
          await queryClient.invalidateQueries({ queryKey: ["admin-submissions"] });
        }
        push("Restaurant created");
      }
      onClose();
    } catch (err) {
      push(err instanceof ApiError ? err.message : "Something went wrong", "error");
    }
  };

  return (
    <Dialog open={open} onClose={onClose} title={isEdit ? "Edit restaurant" : "Add restaurant"}>
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        {!isEdit && prefill && (
          <p className="rounded-md bg-amber-50 px-3 py-2 text-sm text-amber-800">
            Filled in from the submission. Add the exact coordinates (and a cover image and discount, if you have them)
            before saving.
          </p>
        )}
        <FormField label="Name" htmlFor="name" error={errors.name?.message}>
          <Input id="name" {...register("name")} />
        </FormField>
        <FormField label="Address" htmlFor="address" error={errors.address?.message}>
          <Input id="address" {...register("address")} />
        </FormField>
        <div className="grid grid-cols-2 gap-3">
          <FormField label="Latitude" htmlFor="latitude" error={errors.latitude?.message}>
            <Input
              id="latitude"
              type="number"
              step="any"
              {...register("latitude")}
              onFocus={(e) => e.currentTarget.select()}
              onPaste={handleCoordinatePaste}
            />
          </FormField>
          <FormField label="Longitude" htmlFor="longitude" error={errors.longitude?.message}>
            <Input
              id="longitude"
              type="number"
              step="any"
              {...register("longitude")}
              onFocus={(e) => e.currentTarget.select()}
              onPaste={handleCoordinatePaste}
            />
          </FormField>
        </div>
        <p className="-mt-2 text-xs text-slate-500">
          Tip: copy the coordinates from Google Maps (right-click the place) and paste them into either box; both boxes
          fill in.
        </p>
        {hasValidCoordinates && (
          <a
            href={`https://www.google.com/maps?q=${latitude},${longitude}`}
            target="_blank"
            rel="noreferrer"
            className="-mt-2 inline-block text-sm text-blue-600 hover:underline"
          >
            Open in Google Maps to verify
          </a>
        )}
        <FormField label="Phone number" htmlFor="phoneNumber" error={errors.phoneNumber?.message}>
          <Input id="phoneNumber" {...register("phoneNumber")} />
        </FormField>
        <FormField
          label="Discount for reservation-code holders (%)"
          htmlFor="discountPercent"
          error={errors.discountPercent?.message}
        >
          <Input
            id="discountPercent"
            type="number"
            min={0}
            max={100}
            step={1}
            {...register("discountPercent")}
            onFocus={(e) => e.currentTarget.select()}
          />
        </FormField>
        <FormField label="Description (Azerbaijani)" htmlFor="description" error={errors.description?.message}>
          <Textarea id="description" rows={3} {...register("description")} />
        </FormField>
        <FormField label="Description (Russian, optional)" htmlFor="descriptionRu" error={errors.descriptionRu?.message}>
          <Textarea id="descriptionRu" rows={3} {...register("descriptionRu")} />
        </FormField>
        <FormField label="Description (English, optional)" htmlFor="descriptionEn" error={errors.descriptionEn?.message}>
          <Textarea id="descriptionEn" rows={3} {...register("descriptionEn")} />
        </FormField>
        <FormField label="Cover image">
          <ImageUploader
            category="restaurants"
            value={imageUrl}
            onChange={(url) => setValue("imageUrl", url, { shouldDirty: true })}
          />
        </FormField>
        {isEdit && <Checkbox label="Active (visible in the mobile app)" {...register("isActive")} />}
        <div className="flex justify-end gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" disabled={isSubmitting}>
            {isEdit ? "Save changes" : "Create restaurant"}
          </Button>
        </div>
      </form>
    </Dialog>
  );
}

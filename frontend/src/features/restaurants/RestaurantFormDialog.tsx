import { useEffect } from "react";
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
import { useCreateRestaurant, useUpdateRestaurant } from "./api";
import type { RestaurantDto } from "../../types";

const schema = z.object({
  name: z.string().trim().min(1, "Name is required").max(200),
  description: z.string().trim().max(4000).optional(),
  address: z.string().trim().min(1, "Address is required").max(400),
  phoneNumber: z.string().trim().max(50).optional(),
  imageUrl: z.string().trim().max(1000).optional(),
  isActive: z.boolean(),
});

type FormValues = z.infer<typeof schema>;

const emptyValues: FormValues = {
  name: "",
  description: "",
  address: "",
  phoneNumber: "",
  imageUrl: "",
  isActive: true,
};

interface RestaurantFormDialogProps {
  open: boolean;
  onClose: () => void;
  restaurant?: RestaurantDto | null;
}

export function RestaurantFormDialog({ open, onClose, restaurant }: RestaurantFormDialogProps) {
  const isEdit = Boolean(restaurant);
  const { push } = useToast();
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
            address: restaurant.address,
            phoneNumber: restaurant.phoneNumber ?? "",
            imageUrl: restaurant.imageUrl ?? "",
            isActive: restaurant.isActive,
          }
        : emptyValues
    );
  }, [open, restaurant, reset]);

  const imageUrl = watch("imageUrl");

  const onSubmit = async (values: FormValues) => {
    const payload = {
      name: values.name,
      description: values.description || null,
      address: values.address,
      phoneNumber: values.phoneNumber || null,
      imageUrl: values.imageUrl || null,
    };
    try {
      if (isEdit && restaurant) {
        await updateMutation.mutateAsync({ id: restaurant.id, body: { ...payload, isActive: values.isActive } });
        push("Restaurant updated");
      } else {
        await createMutation.mutateAsync(payload);
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
        <FormField label="Name" htmlFor="name" error={errors.name?.message}>
          <Input id="name" {...register("name")} />
        </FormField>
        <FormField label="Address" htmlFor="address" error={errors.address?.message}>
          <Input id="address" {...register("address")} />
        </FormField>
        <FormField label="Phone number" htmlFor="phoneNumber" error={errors.phoneNumber?.message}>
          <Input id="phoneNumber" {...register("phoneNumber")} />
        </FormField>
        <FormField label="Description" htmlFor="description" error={errors.description?.message}>
          <Textarea id="description" rows={3} {...register("description")} />
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

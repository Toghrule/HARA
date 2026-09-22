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
import { contactTypeLabels, numericEnumEntries } from "../../lib/enumLabels";
import { useCreateContact, useUpdateContact } from "./contactsApi";
import { ContactType } from "../../types";
import type { ContactInfoDto } from "../../types";

const schema = z
  .object({
    type: z.coerce.number().int() as unknown as z.ZodType<ContactType>,
    value: z.string().trim().min(1, "Value is required").max(320),
    label: z.string().trim().max(100).optional(),
    isActive: z.boolean(),
  })
  .superRefine((data, ctx) => {
    if (data.type === ContactType.Email && !z.string().email().safeParse(data.value).success) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, message: "Enter a valid email address", path: ["value"] });
    }
  });

type FormValues = z.infer<typeof schema>;

const emptyValues: FormValues = { type: ContactType.Phone, value: "", label: "", isActive: true };

interface ContactFormDialogProps {
  open: boolean;
  onClose: () => void;
  contact?: ContactInfoDto | null;
  nextSortOrder: number;
}

export function ContactFormDialog({ open, onClose, contact, nextSortOrder }: ContactFormDialogProps) {
  const isEdit = Boolean(contact);
  const { push } = useToast();
  const createMutation = useCreateContact();
  const updateMutation = useUpdateContact();

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({ resolver: zodResolver(schema), defaultValues: emptyValues });

  useEffect(() => {
    if (!open) return;
    reset(
      contact
        ? { type: contact.type, value: contact.value, label: contact.label ?? "", isActive: contact.isActive }
        : emptyValues
    );
  }, [open, contact, reset]);

  const onSubmit = async (values: FormValues) => {
    const payload = { type: values.type, value: values.value, label: values.label || null };
    try {
      if (isEdit && contact) {
        await updateMutation.mutateAsync({
          id: contact.id,
          body: { ...payload, sortOrder: contact.sortOrder, isActive: values.isActive },
        });
        push("Contact updated");
      } else {
        await createMutation.mutateAsync({ ...payload, sortOrder: nextSortOrder });
        push("Contact created");
      }
      onClose();
    } catch (err) {
      push(err instanceof ApiError ? err.message : "Something went wrong", "error");
    }
  };

  return (
    <Dialog open={open} onClose={onClose} title={isEdit ? "Edit contact" : "Add contact"}>
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <FormField label="Type" htmlFor="type" error={errors.type?.message}>
          <Select id="type" {...register("type", { valueAsNumber: true })}>
            {numericEnumEntries(ContactType).map(([key, value]) => (
              <option key={key} value={value}>
                {contactTypeLabels[value as ContactType]}
              </option>
            ))}
          </Select>
        </FormField>
        <FormField label="Value" htmlFor="value" error={errors.value?.message}>
          <Input id="value" {...register("value")} />
        </FormField>
        <FormField label="Label (optional)" htmlFor="label" error={errors.label?.message}>
          <Input id="label" placeholder="e.g. Support line" {...register("label")} />
        </FormField>
        {isEdit && <Checkbox label="Active (shown in the mobile app)" {...register("isActive")} />}
        <div className="flex justify-end gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" disabled={isSubmitting}>
            {isEdit ? "Save changes" : "Create contact"}
          </Button>
        </div>
      </form>
    </Dialog>
  );
}

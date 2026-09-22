import { useEffect } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { PageHeader } from "../../components/ui/PageHeader";
import { Button } from "../../components/ui/Button";
import { Input } from "../../components/ui/Input";
import { Textarea } from "../../components/ui/Textarea";
import { FormField } from "../../components/ui/FormField";
import { ImageUploader } from "../../components/ui/ImageUploader";
import { Spinner } from "../../components/ui/Spinner";
import { useToast } from "../../components/ui/Toast";
import { ApiError } from "../../lib/api";
import { useAboutUs, useUpdateAboutUs } from "./aboutUsApi";

const schema = z.object({
  companyName: z.string().trim().min(1, "Company name is required").max(200),
  description: z.string().trim().min(1, "Description is required").max(8000),
  logoUrl: z.string().trim().max(1000).optional(),
});

type FormValues = z.infer<typeof schema>;

export function AboutUsPage() {
  const { data, isLoading } = useAboutUs();
  const updateMutation = useUpdateAboutUs();
  const { push } = useToast();

  const {
    register,
    handleSubmit,
    reset,
    setValue,
    watch,
    formState: { errors, isSubmitting, isDirty },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { companyName: "", description: "", logoUrl: "" },
  });

  useEffect(() => {
    if (data) {
      reset({ companyName: data.companyName, description: data.description, logoUrl: data.logoUrl ?? "" });
    }
  }, [data, reset]);

  const logoUrl = watch("logoUrl");

  const onSubmit = async (values: FormValues) => {
    try {
      await updateMutation.mutateAsync({
        companyName: values.companyName,
        description: values.description,
        logoUrl: values.logoUrl || null,
      });
      push("About Us content saved");
    } catch (err) {
      push(err instanceof ApiError ? err.message : "Failed to save", "error");
    }
  };

  if (isLoading) return <Spinner />;

  return (
    <div className="space-y-6">
      <PageHeader title="About Us" description="Shown on the mobile app's About Us screen." />
      <form onSubmit={handleSubmit(onSubmit)} className="max-w-xl space-y-4 rounded-lg border border-slate-200 bg-white p-6">
        <FormField label="Company name" htmlFor="companyName" error={errors.companyName?.message}>
          <Input id="companyName" {...register("companyName")} />
        </FormField>
        <FormField label="Description" htmlFor="description" error={errors.description?.message}>
          <Textarea id="description" rows={6} {...register("description")} />
        </FormField>
        <FormField label="Logo">
          <ImageUploader category="company" value={logoUrl} onChange={(url) => setValue("logoUrl", url, { shouldDirty: true })} />
        </FormField>
        <div className="flex justify-end">
          <Button type="submit" disabled={isSubmitting || !isDirty}>
            Save changes
          </Button>
        </div>
      </form>
    </div>
  );
}

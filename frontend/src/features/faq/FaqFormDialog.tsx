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
import { useToast } from "../../components/ui/Toast";
import { ApiError } from "../../lib/api";
import { useCreateFaqItem, useUpdateFaqItem } from "./api";
import type { FaqItemDto } from "../../types";

const schema = z.object({
  question: z.string().trim().min(1, "Question is required").max(500),
  answer: z.string().trim().min(1, "Answer is required").max(4000),
  isActive: z.boolean(),
});

type FormValues = z.infer<typeof schema>;

const emptyValues: FormValues = { question: "", answer: "", isActive: true };

interface FaqFormDialogProps {
  open: boolean;
  onClose: () => void;
  faqItem?: FaqItemDto | null;
  nextSortOrder: number;
}

export function FaqFormDialog({ open, onClose, faqItem, nextSortOrder }: FaqFormDialogProps) {
  const isEdit = Boolean(faqItem);
  const { push } = useToast();
  const createMutation = useCreateFaqItem();
  const updateMutation = useUpdateFaqItem();

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({ resolver: zodResolver(schema), defaultValues: emptyValues });

  useEffect(() => {
    if (!open) return;
    reset(
      faqItem
        ? { question: faqItem.question, answer: faqItem.answer, isActive: faqItem.isActive }
        : emptyValues
    );
  }, [open, faqItem, reset]);

  const onSubmit = async (values: FormValues) => {
    try {
      if (isEdit && faqItem) {
        await updateMutation.mutateAsync({
          id: faqItem.id,
          body: { question: values.question, answer: values.answer, sortOrder: faqItem.sortOrder, isActive: values.isActive },
        });
        push("FAQ entry updated");
      } else {
        await createMutation.mutateAsync({ question: values.question, answer: values.answer, sortOrder: nextSortOrder });
        push("FAQ entry created");
      }
      onClose();
    } catch (err) {
      push(err instanceof ApiError ? err.message : "Something went wrong", "error");
    }
  };

  return (
    <Dialog open={open} onClose={onClose} title={isEdit ? "Edit FAQ entry" : "Add FAQ entry"}>
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <FormField label="Question" htmlFor="question" error={errors.question?.message}>
          <Input id="question" {...register("question")} />
        </FormField>
        <FormField label="Answer" htmlFor="answer" error={errors.answer?.message}>
          <Textarea id="answer" rows={4} {...register("answer")} />
        </FormField>
        {isEdit && <Checkbox label="Active (shown in the mobile app)" {...register("isActive")} />}
        <div className="flex justify-end gap-2 pt-2">
          <Button type="button" variant="secondary" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" disabled={isSubmitting}>
            {isEdit ? "Save changes" : "Create entry"}
          </Button>
        </div>
      </form>
    </Dialog>
  );
}

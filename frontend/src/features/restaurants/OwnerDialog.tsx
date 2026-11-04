import { useState } from "react";
import { Copy, Wand2 } from "lucide-react";
import { Dialog } from "../../components/ui/Dialog";
import { Button } from "../../components/ui/Button";
import { Input } from "../../components/ui/Input";
import { FormField } from "../../components/ui/FormField";
import { Spinner } from "../../components/ui/Spinner";
import { useToast } from "../../components/ui/Toast";
import { ApiError } from "../../lib/api";
import { useCreateRestaurantOwner, useRestaurantOwner } from "./api";
import type { RestaurantDto } from "../../types";

/** A password the admin can read out over the phone: no look-alike characters, always with a capital, lowercase letters and digits. */
function generatePassword() {
  const letters = "abcdefghijkmnpqrstuvwxyz";
  const digits = "23456789";
  const pick = (set: string) => set[crypto.getRandomValues(new Uint32Array(1))[0] % set.length];
  return [pick(letters.toUpperCase()), ...Array.from({ length: 5 }, () => pick(letters)), ...Array.from({ length: 3 }, () => pick(digits))].join("");
}

interface OwnerDialogProps {
  restaurant: RestaurantDto | null;
  onClose: () => void;
}

/**
 * For a restaurant the admin created without a sign-up: gives it an owner. The admin picks the email and a password and
 * hands them to the owner (they are shown once, here); the owner accepts the terms the first time they sign in.
 */
export function OwnerDialog({ restaurant, onClose }: OwnerDialogProps) {
  return (
    <Dialog open={restaurant !== null} onClose={onClose} title={restaurant ? `Owner of ${restaurant.name}` : "Owner"}>
      {restaurant && <OwnerBody restaurant={restaurant} onClose={onClose} />}
    </Dialog>
  );
}

function OwnerBody({ restaurant, onClose }: { restaurant: RestaurantDto; onClose: () => void }) {
  const { data: owner, isLoading } = useRestaurantOwner(restaurant.id);
  const create = useCreateRestaurantOwner(restaurant.id);
  const { push } = useToast();
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState(generatePassword);
  const [created, setCreated] = useState<{ email: string; password: string } | null>(null);
  const [error, setError] = useState<string | null>(null);

  if (isLoading) return <Spinner />;

  if (created) {
    const text = `HARA\nEmail: ${created.email}\nPassword: ${created.password}`;
    return (
      <div className="space-y-4">
        <p className="text-sm text-slate-600">
          The account is ready. Give these to the owner now (the password is not shown again). They accept the terms when they first sign in.
        </p>
        <pre className="rounded-md bg-slate-100 p-3 text-sm">{text}</pre>
        <div className="flex justify-end gap-2">
          <Button type="button" variant="secondary" onClick={() => navigator.clipboard.writeText(text).then(() => push("Copied"))}>
            <Copy className="h-4 w-4" />
            Copy
          </Button>
          <Button type="button" onClick={onClose}>
            Done
          </Button>
        </div>
      </div>
    );
  }

  if (owner) {
    return (
      <div className="space-y-3">
        <p className="text-sm text-slate-600">This restaurant already has an owner.</p>
        <dl className="space-y-1 text-sm">
          <div>
            <dt className="inline text-slate-500">Name: </dt>
            <dd className="inline font-medium">{owner.fullName}</dd>
          </div>
          <div>
            <dt className="inline text-slate-500">Email: </dt>
            <dd className="inline font-medium">{owner.email}</dd>
          </div>
          <div>
            <dt className="inline text-slate-500">Phone: </dt>
            <dd className="inline font-medium">{owner.phoneNumber ?? "—"}</dd>
          </div>
        </dl>
        <p className="text-xs text-slate-500">A forgotten password is handled under Password resets.</p>
        <div className="flex justify-end">
          <Button type="button" onClick={onClose}>
            Close
          </Button>
        </div>
      </div>
    );
  }

  const submit = async (event: React.FormEvent) => {
    event.preventDefault();
    setError(null);
    try {
      await create.mutateAsync({ email: email.trim(), password, fullName: fullName.trim(), phoneNumber: phone.trim() || undefined });
      setCreated({ email: email.trim(), password });
    } catch (err) {
      setError(err instanceof ApiError ? Object.values(err.errors ?? {}).flat().join(" ") || err.message : "Failed to create the owner");
    }
  };

  return (
    <form onSubmit={submit} className="space-y-4">
      <p className="text-sm text-slate-600">This restaurant has no owner. Create an account for them and hand over the email and password.</p>
      <FormField label="Owner name" htmlFor="ownerName">
        <Input id="ownerName" value={fullName} onChange={(e) => setFullName(e.target.value)} required />
      </FormField>
      <FormField label="Email (the sign-in)" htmlFor="ownerEmail">
        <Input id="ownerEmail" type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
      </FormField>
      <FormField label="Phone (optional)" htmlFor="ownerPhone">
        <Input id="ownerPhone" value={phone} onChange={(e) => setPhone(e.target.value)} />
      </FormField>
      <FormField label="Password" htmlFor="ownerPassword">
        <div className="flex gap-2">
          <Input id="ownerPassword" value={password} onChange={(e) => setPassword(e.target.value)} required />
          <Button type="button" variant="secondary" onClick={() => setPassword(generatePassword())} title="Make a new one">
            <Wand2 className="h-4 w-4" />
          </Button>
        </div>
      </FormField>
      {error && <p className="text-sm text-red-600">{error}</p>}
      <div className="flex justify-end gap-2">
        <Button type="button" variant="secondary" onClick={onClose}>
          Cancel
        </Button>
        <Button type="submit" disabled={create.isPending}>
          Create owner
        </Button>
      </div>
    </form>
  );
}

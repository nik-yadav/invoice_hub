"use client";

import { Suspense, useEffect, useState, type SubmitEvent } from "react";
import { useSearchParams } from "next/navigation";

// Sign-in and consent page for the backend's OAuth flow. The backend's /oauth/authorize sends
// the browser here with ?request_id=…; approving or cancelling returns a redirectTo URL
// (the client's validated callback), which the browser then follows.

type View = "loading" | "invalid" | "login" | "done" | "cancel";

type AuthRequest = {
  clientName: string;
  scopes: string[];
  redirectHost: string;
};

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3001";

const SCOPE_LABELS: Record<string, string> = {
  "invoices:read": "Read your invoices: numbers, dates, customers, routes, amounts and payment status",
};

const focus =
  "focus-visible:outline focus-visible:outline-[3px] focus-visible:outline-offset-2 focus-visible:outline-[#3547D4] dark:focus-visible:outline-[#7C8BFF]";
const muted = "text-[#5A6580] dark:text-[#9AA5BF]";
const input = `w-full min-h-12 rounded-[10px] border border-[#D8DEEA] bg-[#F4F6FB] px-3.5 py-3 text-[#14213D] dark:border-[#2A3348] dark:bg-[#1D2538] dark:text-[#E8ECF6] ${focus}`;
const primary = `w-full min-h-12 rounded-xl bg-[#3547D4] px-4 py-3 font-semibold text-white disabled:cursor-progress disabled:opacity-60 dark:bg-[#7C8BFF] dark:text-[#0B101C] ${focus}`;
const ghost = `mt-2.5 w-full min-h-12 rounded-xl border border-[#D8DEEA] px-4 py-3 font-semibold disabled:opacity-60 dark:border-[#2A3348] ${focus}`;

async function post(path: string, body?: object) {
  const res = await fetch(`${API_URL}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body ?? {}),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.message ?? "Something went wrong. Try again.");
  return data;
}

function AuthForm() {
  const requestId = useSearchParams().get("request_id") ?? "";

  const [view, setView] = useState<View>(requestId ? "loading" : "invalid");
  const [request, setRequest] = useState<AuthRequest | null>(null);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPw, setShowPw] = useState(false);
  const [error, setError] = useState(
    requestId ? "" : "This page opens from your app's sign-in. Start again from your terminal.",
  );
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!requestId) return;
    fetch(`${API_URL}/oauth/requests/${encodeURIComponent(requestId)}`)
      .then(async (res) => {
        const data = await res.json().catch(() => ({}));
        if (!res.ok) throw new Error(data.message ?? "This sign-in link is not valid.");
        setRequest(data);
        setView("login");
      })
      .catch((err) => {
        setError(err instanceof Error ? err.message : "Could not load this sign-in request.");
        setView("invalid");
      });
  }, [requestId]);

  async function onSubmit(e: SubmitEvent<HTMLFormElement>) {
    e.preventDefault();
    setError("");
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email.trim())) return setError("Enter a valid email address.");
    if (!password) return setError("Enter your password.");

    setLoading(true);
    try {
      const data = await post(`/oauth/requests/${encodeURIComponent(requestId)}/approve`, {
        email: email.trim(),
        password,
      });
      setPassword("");
      setView("done");
      setTimeout(() => window.location.assign(data.redirectTo), 800);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Sign-in failed. Check your details and try again.");
    } finally {
      setLoading(false);
    }
  }

  async function cancel() {
    setLoading(true);
    try {
      const data = await post(`/oauth/requests/${encodeURIComponent(requestId)}/deny`);
      setView("cancel");
      window.location.assign(data.redirectTo);
    } catch {
      // The request already expired: nothing to tell the client, it will time out on its own.
      setView("cancel");
    } finally {
      setLoading(false);
    }
  }

  const client = request?.clientName ?? "Claude";

  return (
    <main className="w-full max-w-[460px]">
      {/* Terminal strip mirrors what the CLI is doing */}
      <div
        aria-live="polite"
        className="overflow-x-auto whitespace-pre rounded-t-[14px] bg-[#101828] px-4 py-3.5 font-mono text-[0.8rem] leading-relaxed text-[#D6DEF0] dark:bg-[#070B14]"
      >
        <span className="text-[#7E8AA8]">$</span> /mcp → invoice-hub → Authenticate
        {"\n"}
        {(view === "loading" || view === "login") && (
          <>
            <span className="text-[#7E8AA8]">Opening browser to authenticate…</span>
            {"\n"}Waiting for sign-in{" "}
            <span className="inline-block h-4 w-2 translate-y-0.5 animate-pulse bg-[#D6DEF0] motion-reduce:animate-none" />
          </>
        )}
        {view === "done" && (
          <>
            <span className="text-[#5CD39A]">✓</span> Authenticated as {email}
            {"\n"}
            <span className="text-[#5CD39A]">✓</span> Sending authorization to {request?.redirectHost}
          </>
        )}
        {view === "cancel" && <>Authentication cancelled.</>}
        {view === "invalid" && <>Sign-in request not found.</>}
      </div>

      <div className="rounded-b-[20px] border border-t-0 border-[#D8DEEA] bg-white p-6 shadow-[0_12px_40px_rgba(20,33,61,0.08)] dark:border-[#2A3348] dark:bg-[#161D2E]">
        {view === "loading" && <p className={muted}>Loading sign-in request…</p>}

        {view === "invalid" && (
          <div>
            <h1 className="mb-2 text-2xl font-bold leading-tight tracking-tight">Can’t continue</h1>
            <p role="alert" className={`mb-2 ${muted}`}>{error}</p>
          </div>
        )}

        {view === "login" && request && (
          <form onSubmit={onSubmit} noValidate>
            <h1 className="mb-2 text-2xl font-bold leading-tight tracking-tight">Sign in to connect {client}</h1>
            <p className={`mb-5 ${muted}`}>
              <b className="text-inherit">{client}</b> wants to access your Transport Invoice Pro account. Sign in to
              allow it.
            </p>

            <div className="mb-4">
              <label htmlFor="email" className="mb-1.5 block text-sm font-semibold">Email</label>
              <input
                id="email" type="email" autoComplete="username" placeholder="you@company.com"
                value={email} onChange={(e) => setEmail(e.target.value)} className={input} required
              />
            </div>

            <div className="mb-4">
              <label htmlFor="password" className="mb-1.5 block text-sm font-semibold">Password</label>
              <div className="relative">
                <input
                  id="password" type={showPw ? "text" : "password"} autoComplete="current-password"
                  value={password} onChange={(e) => setPassword(e.target.value)} className={`${input} pr-16`} required
                />
                <button
                  type="button" onClick={() => setShowPw((s) => !s)} aria-pressed={showPw}
                  className={`absolute inset-y-1.5 right-1.5 rounded-lg px-2.5 text-sm text-[#3547D4] dark:text-[#7C8BFF] ${focus}`}
                >
                  {showPw ? "Hide" : "Show"}
                </button>
              </div>
            </div>

            {error && (
              <p role="alert" className="mb-3.5 text-sm text-[#B3261E] dark:text-[#FF8A80]">{error}</p>
            )}

            <div className={`mb-4 rounded-xl border border-[#D8DEEA] bg-[#F4F6FB] px-3.5 py-3 text-sm dark:border-[#2A3348] dark:bg-[#1D2538] ${muted}`}>
              <b className="text-[#14213D] dark:text-[#E8ECF6]">{client} will be able to:</b>
              <ul className="mt-1.5 list-disc pl-5">
                {request.scopes.map((scope) => (
                  <li key={scope}>{SCOPE_LABELS[scope] ?? scope}</li>
                ))}
              </ul>
              <p className="mt-1.5">It can’t create, change or delete anything, or see your password.</p>
            </div>

            <button type="submit" disabled={loading} className={primary}>
              {loading ? "Signing in…" : "Sign in and allow"}
            </button>
            <button type="button" onClick={cancel} disabled={loading} className={ghost}>Cancel</button>
          </form>
        )}

        {view === "done" && (
          <div>
            <h1 className="mb-2 text-2xl font-bold leading-tight tracking-tight">You’re connected</h1>
            <p className={muted}>Signed in as {email}. Returning you to {client}… You can close this tab afterwards.</p>
          </div>
        )}

        {view === "cancel" && (
          <div>
            <h1 className="mb-2 text-2xl font-bold leading-tight tracking-tight">Sign-in cancelled</h1>
            <p className={muted}>Nothing was shared. Authenticate again from your terminal when you’re ready.</p>
          </div>
        )}

        <p className={`mt-4 text-center text-xs ${muted}`}>
          Access lasts until you revoke it. Tokens are stored by {client} on your computer.
        </p>
      </div>
    </main>
  );
}

export default function Auth() {
  return (
    <div className="flex min-h-screen justify-center bg-[#EEF1F7] px-4 py-8 text-[#14213D] dark:bg-[#0B101C] dark:text-[#E8ECF6]">
      <Suspense>
        <AuthForm />
      </Suspense>
    </div>
  );
}

"use client";

import { Suspense, useState, type FormEvent } from "react";
import { useSearchParams } from "next/navigation";

type View = "login" | "done" | "cancel";

const isLocal = (u: string) => /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?\//.test(u);

const withParams = (base: string, params: Record<string, string>) => {
  const url = new URL(base);
  Object.entries(params).forEach(([k, v]) => url.searchParams.set(k, v));
  return url.toString();
};

const focus =
  "focus-visible:outline focus-visible:outline-[3px] focus-visible:outline-offset-2 focus-visible:outline-[#3547D4] dark:focus-visible:outline-[#7C8BFF]";
const muted = "text-[#5A6580] dark:text-[#9AA5BF]";
const input = `w-full min-h-12 rounded-[10px] border border-[#D8DEEA] bg-[#F4F6FB] px-3.5 py-3 text-[#14213D] dark:border-[#2A3348] dark:bg-[#1D2538] dark:text-[#E8ECF6] ${focus}`;
const primary = `w-full min-h-12 rounded-xl bg-[#3547D4] px-4 py-3 font-semibold text-white disabled:cursor-progress disabled:opacity-60 dark:bg-[#7C8BFF] dark:text-[#0B101C] ${focus}`;
const ghost = `mt-2.5 w-full min-h-12 rounded-xl border border-[#D8DEEA] px-4 py-3 font-semibold dark:border-[#2A3348] ${focus}`;
const link = "text-[#3547D4] underline dark:text-[#7C8BFF]";

function AuthForm() {
  const sp = useSearchParams();
  const server = sp.get("server") ?? "acme-mcp";
  const redirect = sp.get("redirect_uri") ?? "";
  const state = sp.get("state") ?? "";
  const local = isLocal(redirect);

  const [view, setView] = useState<View>("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPw, setShowPw] = useState(false);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [token, setToken] = useState("");
  const [copied, setCopied] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError("");
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email.trim())) return setError("Enter a valid email address.");
    if (password.length < 8) return setError("Password must be at least 8 characters.");

    setLoading(true);
    try {
      const res = await fetch("/api/mcp/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: email.trim(), password, redirect_uri: redirect, state }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? "Sign-in failed. Check your details and try again.");

      setToken(data.token);
      setPassword("");
      setView("done");
      if (local) {
        setTimeout(() => {
          window.location.href = withParams(redirect, { code: data.token, state });
        }, 1200);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong. Try again.");
    } finally {
      setLoading(false);
    }
  }

  function cancel() {
    setView("cancel");
    if (local) window.location.href = withParams(redirect, { error: "access_denied", state });
  }

  async function copy() {
    try {
      await navigator.clipboard.writeText(token);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      /* clipboard blocked: the token is selectable in the box */
    }
  }

  const cmd = `claude mcp add --transport http ${server} https://mcp.example.com`;

  return (
    <main className="w-full max-w-[460px]">
      {/* Terminal strip mirrors what the CLI is doing */}
      <div
        aria-live="polite"
        className="overflow-x-auto whitespace-pre rounded-t-[14px] bg-[#101828] px-4 py-3.5 font-mono text-[0.8rem] leading-relaxed text-[#D6DEF0] dark:bg-[#070B14]"
      >
        <span className="text-[#7E8AA8]">$</span> {cmd}
        {"\n"}
        {view === "login" && (
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
            <span className="text-[#5CD39A]">✓</span> Token saved. {server} is ready
          </>
        )}
        {view === "cancel" && <>Authentication cancelled. No server was added.</>}
      </div>

      <div className="rounded-b-[20px] border border-t-0 border-[#D8DEEA] bg-white p-6 shadow-[0_12px_40px_rgba(20,33,61,0.08)] dark:border-[#2A3348] dark:bg-[#161D2E]">
        {view === "login" && (
          <form onSubmit={onSubmit} noValidate>
            <h1 className="mb-2 text-2xl font-bold leading-tight tracking-tight">Sign in to connect your terminal</h1>
            <p className={`mb-5 ${muted}`}>
              Claude Code asked to add <b className="text-inherit">{server}</b>. Sign in and we’ll send an access token back
              to the terminal.
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

            <div className="mb-4 flex justify-between text-sm">
              <a href="#" className={link}>Forgot password?</a>
              <a href="#" className={link}>Create account</a>
            </div>

            <p className={`mb-4 rounded-xl border border-[#D8DEEA] bg-[#F4F6FB] px-3.5 py-3 text-sm dark:border-[#2A3348] dark:bg-[#1D2538] ${muted}`}>
              <b className="text-[#14213D] dark:text-[#E8ECF6]">This token lets Claude Code</b> call tools on your MCP server
              as you. It can’t change your password or billing.
            </p>

            <button type="submit" disabled={loading} className={primary}>
              {loading ? "Signing in…" : "Sign in and continue"}
            </button>
            <button type="button" onClick={cancel} className={ghost}>Cancel</button>
          </form>
        )}

        {view === "done" && (
          <div>
            <h1 className="mb-2 text-2xl font-bold leading-tight tracking-tight">You’re connected</h1>
            <p className={`mb-5 ${muted}`}>
              {local
                ? `Signed in as ${email}. Sending your token to the terminal now.`
                : `Signed in as ${email}. You can return to your terminal.`}
            </p>

            <label className="mb-1.5 block text-sm font-semibold">Access token</label>
            <div className="mb-2 flex gap-2">
              <code className="min-w-0 flex-1 overflow-x-auto whitespace-nowrap rounded-[10px] border border-[#D8DEEA] bg-[#F4F6FB] px-3.5 py-3 font-mono text-[0.8rem] dark:border-[#2A3348] dark:bg-[#1D2538]">
                {token}
              </code>
              <button
                type="button" onClick={copy}
                className={`min-w-[72px] rounded-[10px] border border-[#D8DEEA] px-3.5 text-sm font-semibold dark:border-[#2A3348] ${focus}`}
              >
                {copied ? "Copied" : "Copy"}
              </button>
            </div>
            {!local && (
              <p className={`mb-5 text-sm ${muted}`}>If your terminal didn’t pick it up, paste this token when it asks.</p>
            )}

            <button type="button" onClick={() => window.close()} className={`${primary} mt-5`}>Done</button>
            <button type="button" onClick={() => { setToken(""); setView("login"); }} className={ghost}>
              Revoke token
            </button>
          </div>
        )}

        {view === "cancel" && (
          <div>
            <h1 className="mb-2 text-2xl font-bold leading-tight tracking-tight">Sign-in cancelled</h1>
            <p className={`mb-5 ${muted}`}>
              No token was created. Run <b className="text-inherit">claude mcp add</b> again when you’re ready.
            </p>
            <button type="button" onClick={() => setView("login")} className={primary}>Back to sign in</button>
          </div>
        )}

        <p className={`mt-4 text-center text-xs ${muted}`}>Tokens are stored by Claude Code on this computer only.</p>
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

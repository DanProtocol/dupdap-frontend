#!/usr/bin/env bash
# Creates 125 GitHub issues for dupdap-frontend
set -e
REPO="dupdab/dupdap-frontend"
ci() {
  local title="$1" body="$2" labels="$3"
  gh issue create --repo "$REPO" --title "$title" --body "$body" --label "$labels" 2>/dev/null || \
  gh issue create --repo "$REPO" --title "$title" --body "$body" 2>/dev/null
  sleep 0.35
}
echo "Creating 125 issues for dupdap-frontend..."

# ── P0 CRITICAL (15) ──────────────────────────────────────────────────────────

ci "[P0] Add zero-test-suite warning — set up Jest + React Testing Library" \
"## Problem
The README explicitly states 'There is no test suite in this repo yet.' There are no unit, integration, or component tests anywhere. Zero coverage means regressions ship silently.

## Acceptance Criteria
- [ ] Install Jest, ts-jest, @testing-library/react, @testing-library/user-event
- [ ] Configure jest.config.ts with jsdom environment and path aliases
- [ ] Add \`npm run test\` script
- [ ] Seed at least one smoke test (renders LandingPage without crashing)
- [ ] CI step runs tests on every PR" \
"bug,P0,testing"

ci "[P0] Token stored in localStorage — vulnerable to XSS; move to httpOnly cookie" \
"## Problem
\`src/lib/api.ts\` and \`src/lib/store.ts\` store the JWT access token in \`localStorage\` under key \`access_token\`. Any XSS vulnerability on the page can steal the token.

## Acceptance Criteria
- [ ] Backend issues token via \`Set-Cookie: access_token=...; HttpOnly; Secure; SameSite=Strict\`
- [ ] Frontend removes localStorage token reads/writes from \`api.ts\` and \`store.ts\`
- [ ] Axios interceptor omits manual \`Authorization\` header (cookie sent automatically)
- [ ] Logout clears cookie via backend \`POST /auth/logout\`
- [ ] Document security rationale in README" \
"security,P0,auth"

ci "[P0] Payment polling uses 5s interval with no AbortController — memory leak on navigation" \
"## Problem
\`src/app/pay/[paymentId]/page.tsx\` sets a \`setInterval\` every 5 seconds. The cleanup \`clearInterval\` in the \`useEffect\` return only fires when the component unmounts normally. If the Axios request is in-flight during navigation, it resolves and calls \`setPayment\` on an unmounted component.

## Acceptance Criteria
- [ ] Use \`AbortController\` to cancel in-flight Axios requests on cleanup
- [ ] \`clearInterval\` is called in the useEffect cleanup function
- [ ] Add a unit test that navigates away mid-poll and asserts no state-update-after-unmount warning" \
"bug,P0,payments"

ci "[P0] No error boundary — any unhandled render error crashes the entire app" \
"## Problem
There is no React Error Boundary anywhere in the component tree. A single throw in any dashboard component renders a blank white screen for the merchant.

## Acceptance Criteria
- [ ] \`src/components/ErrorBoundary.tsx\` wrapping the app layout
- [ ] Friendly fallback UI with 'Something went wrong' and a reload button
- [ ] Error reported to Sentry (or console in dev)
- [ ] Dashboard route-level boundaries to contain failures to individual panels" \
"bug,P0,architecture"

ci "[P0] API base URL exposed client-side — NEXT_PUBLIC_API_URL can point to any origin" \
"## Problem
\`NEXT_PUBLIC_API_URL\` is the only env variable and defaults to \`http://localhost:3000/api/v1\`. In production, misconfiguring this (or leaving it unset) silently sends requests to localhost. There is no build-time validation.

## Acceptance Criteria
- [ ] Validate \`NEXT_PUBLIC_API_URL\` is a valid HTTPS URL at build time in \`next.config.js\` (warn or fail if not set in production)
- [ ] Add \`NEXT_PUBLIC_API_URL\` to CI environment
- [ ] Document required env vars in README with examples" \
"security,P0,architecture"

ci "[P0] No CSRF protection on API mutations from server-side Next.js routes" \
"## Problem
The app makes POST/PATCH/DELETE requests from the browser with a JWT in localStorage. If the token is moved to a cookie (see token-storage issue), all state-mutating requests become vulnerable to CSRF without a mitigation strategy.

## Acceptance Criteria
- [ ] Implement double-submit cookie or synchronizer token CSRF protection
- [ ] Backend validates \`X-CSRF-Token\` header on all non-GET requests
- [ ] Frontend sends CSRF token on every mutation
- [ ] Document protection approach" \
"security,P0,auth"

ci "[P0] Missing loading and error states in dashboard — data fetches use \`any\` type" \
"## Problem
\`src/app/dashboard/page.tsx\` uses \`useState<any[]>\` for payments and stats. No TypeScript types for API responses means type errors are silent. Error states from failed API calls are not handled — the page just shows empty data.

## Acceptance Criteria
- [ ] Define \`Payment\`, \`PaymentStat\`, \`Settlement\` TypeScript interfaces in \`src/types/\`
- [ ] Replace all \`any\` in dashboard components with typed interfaces
- [ ] Add error state handling: show error banner on API failure
- [ ] Retry button on error state" \
"bug,P0,dashboard"

ci "[P0] No auth guard on dashboard routes — unauthenticated users can access /dashboard" \
"## Problem
The \`/dashboard\` layout has no server-side or client-side auth check. Unauthenticated users who navigate directly to \`/dashboard\` see the merchant interface until the API calls fail.

## Acceptance Criteria
- [ ] \`src/app/dashboard/layout.tsx\` checks Zustand auth state on mount
- [ ] Redirect to \`/auth/login\` if no token exists
- [ ] Server-side middleware (\`middleware.ts\`) protects \`/dashboard/*\` routes
- [ ] Add test: unauthenticated GET /dashboard redirects to /auth/login" \
"security,P0,auth"

ci "[P0] settlementsApi, webhooksApi, merchantApi missing from dashboard pages — pages likely broken" \
"## Problem
\`src/lib/api.ts\` defines \`settlementsApi\`, \`webhooksApi\`, \`merchantApi\` but the dashboard pages for settlements, webhooks, and settings have no corresponding data-fetching. The pages either render empty or throw runtime errors.

## Acceptance Criteria
- [ ] Implement \`/dashboard/settlements\` page using \`settlementsApi.list()\`
- [ ] Implement \`/dashboard/webhooks\` page using \`webhooksApi.list()\` and create/delete
- [ ] Implement \`/dashboard/settings\` page using \`merchantApi.profile()\` and update
- [ ] All pages handle loading, empty, and error states" \
"bug,P0,dashboard"

ci "[P0] /pay/[paymentId] uses polling — switch to WebSocket for real-time status updates" \
"## Problem
The payment page polls every 5 seconds. This adds unnecessary server load and creates 0–5s lag in status updates, making the checkout UX feel slow.

## Acceptance Criteria
- [ ] Connect to backend WebSocket gateway on mount
- [ ] Subscribe to payment room by payment ID
- [ ] Stop polling when WebSocket event received
- [ ] Fall back to polling if WebSocket connection fails
- [ ] Show 'Waiting for payment...' live indicator" \
"enhancement,P0,payments"

ci "[P0] No Content Security Policy headers — XSS vector for injected scripts" \
"## Problem
\`next.config.js\` sets no security headers. Without a CSP, injected scripts can exfiltrate tokens or perform actions as the merchant.

## Acceptance Criteria
- [ ] Add CSP header in \`next.config.js\` \`headers()\` config
- [ ] \`default-src 'self'\`, restrict \`script-src\`, \`connect-src\` to known origins
- [ ] Add \`X-Frame-Options: DENY\`, \`X-Content-Type-Options: nosniff\`
- [ ] Verify CSP does not break Stellar wallet interaction
- [ ] Test with Mozilla Observatory or securityheaders.com" \
"security,P0,auth"

ci "[P0] Merchant registration form has no client-side validation" \
"## Problem
The register form at \`/auth/register\` submits raw form data with no client-side validation. Users discover errors only after a network round-trip.

## Acceptance Criteria
- [ ] Email format validation
- [ ] Password minimum length (8 chars) and strength indicator
- [ ] Business name minimum 2 chars
- [ ] Country dropdown with valid ISO country codes
- [ ] Inline field error messages using react-hook-form + zod" \
"bug,P0,auth"

ci "[P0] QR code shows web+stellar URI but Stellar mobile wallets expect SEP-0007 format" \
"## Problem
\`/pay/[paymentId]\` constructs a QR with \`web+stellar:pay?destination=...\` URI. This is SEP-0007 but the parameters (\`asset_code\`, \`asset_issuer\`, \`memo_type=text\`) need to be precisely formatted for wallet compatibility. Missing \`asset_code=USDC\` and \`asset_issuer\` means most wallets default to XLM.

## Acceptance Criteria
- [ ] Include \`asset_code=USDC&asset_issuer=<issuer>\` in URI
- [ ] Include \`memo_type=text\`
- [ ] Test QR with Lobstr, Solar, and Freighter wallets
- [ ] Document supported wallet list" \
"bug,P0,payments"

ci "[P0] No rate limiting on login form — brute-force attack possible" \
"## Problem
The login page (\`/auth/login\`) has no client-side rate limiting, no CAPTCHA, and no lockout. An attacker can attempt unlimited password guesses.

## Acceptance Criteria
- [ ] After 5 failed login attempts, show CAPTCHA (hCaptcha or Cloudflare Turnstile)
- [ ] Disable submit button with countdown after 3 consecutive failures
- [ ] Display 'Too many attempts' message
- [ ] Backend rate limiting already exists; this is client-side UX reinforcement" \
"security,P0,auth"

ci "[P0] Analytics dashboard page is empty — recharts installed but not used" \
"## Problem
\`recharts\` is a dependency and \`/dashboard/analytics\` route exists, but there is no implementation. Merchants see a blank page.

## Acceptance Criteria
- [ ] Fetch analytics data from \`GET /merchant/analytics\`
- [ ] Line chart: payment volume over last 30 days
- [ ] Bar chart: payments by status
- [ ] KPI cards: conversion rate, avg order value, total revenue
- [ ] Date range picker" \
"bug,P0,dashboard"

# ── P1 HIGH (30) ──────────────────────────────────────────────────────────────

ci "[P1] Extract API types into shared types module — remove all \`any\` from components" \
"## Problem
Dashboard components use \`useState<any>\` throughout. Type mismatches between API responses and UI components go undetected until runtime.

## Acceptance Criteria
- [ ] \`src/types/api.ts\` — Payment, Settlement, Merchant, Webhook, Analytics response types
- [ ] Replace all \`any\` type usages in components with typed interfaces
- [ ] \`strict: true\` in tsconfig.json
- [ ] Zero TypeScript errors in \`tsc --noEmit\`" \
"quality,P1,architecture"

ci "[P1] Implement Freighter wallet integration for customer payment flow" \
"## Problem
\`/pay/[paymentId]\` shows instructions but does not actually integrate with any Stellar wallet. Customers must manually copy the Stellar URI. Freighter is the most common browser wallet.

## Acceptance Criteria
- [ ] Detect Freighter extension presence
- [ ] 'Pay with Freighter' button that constructs and submits the approve + deposit transaction
- [ ] Show transaction hash after submission
- [ ] Fallback to QR code if Freighter not detected
- [ ] Mobile: deep link to Lobstr/Solar app" \
"enhancement,P1,payments"

ci "[P1] Add Sentry error tracking to frontend" \
"## Problem
Frontend errors are untracked. If a merchant's dashboard breaks, there is no visibility.

## Acceptance Criteria
- [ ] \`@sentry/nextjs\` installed and configured
- [ ] \`NEXT_PUBLIC_SENTRY_DSN\` env var
- [ ] Source maps uploaded in production build
- [ ] Sentry wraps the Error Boundary
- [ ] User context (merchant ID) set on Sentry scope after login" \
"observability,P1,architecture"

ci "[P1] Implement payments list page with pagination and filtering" \
"## Problem
\`/dashboard/payments\` route exists but no implementation is visible. Merchants cannot view, search, or filter their payment history.

## Acceptance Criteria
- [ ] Table with columns: reference, amount, status, date, customer email
- [ ] Pagination (prev/next, page size 20)
- [ ] Filter by status dropdown
- [ ] Search by reference number
- [ ] Click row to expand payment detail
- [ ] Copy payment link button" \
"enhancement,P1,dashboard"

ci "[P1] Add payment creation modal/form to dashboard" \
"## Problem
There is no UI for merchants to create a payment from the dashboard. \`paymentsApi.create()\` is defined but not wired up.

## Acceptance Criteria
- [ ] 'New Payment' button on dashboard and payments page
- [ ] Modal form: amount, description, customer email, expiry
- [ ] Client-side validation with inline errors
- [ ] On success: show QR code and payment link in modal
- [ ] Copy-to-clipboard for payment link" \
"enhancement,P1,dashboard"

ci "[P1] Add settlements page with status indicators and download" \
"## Problem
\`/dashboard/settlements\` route exists but is unimplemented. Merchants cannot see their settlement history.

## Acceptance Criteria
- [ ] Table: settlement ID, date, gross, fee, net, status, bank reference
- [ ] Status badges: PROCESSING, PENDING_APPROVAL, COMPLETED, FAILED
- [ ] Date range filter
- [ ] CSV download button
- [ ] Settlement detail modal with fee breakdown" \
"enhancement,P1,dashboard"

ci "[P1] Add webhook management page" \
"## Problem
\`/dashboard/webhooks\` is unimplemented. Merchants cannot register or manage webhook endpoints from the UI.

## Acceptance Criteria
- [ ] List registered webhooks with URL, events, status
- [ ] 'Add Webhook' form: URL, event type checkboxes, secret
- [ ] Delete webhook with confirmation dialog
- [ ] Test webhook button (sends ping event)
- [ ] Show last delivery status per webhook" \
"enhancement,P1,dashboard"

ci "[P1] Implement merchant profile and settings page" \
"## Problem
\`/dashboard/settings\` is unimplemented. Merchants cannot update their profile, business name, or notification preferences.

## Acceptance Criteria
- [ ] Business profile section: name, email, country, bank account
- [ ] Change password form
- [ ] API key management: list, generate, revoke
- [ ] Notification preferences: email toggles per event type
- [ ] Save changes with optimistic UI update" \
"enhancement,P1,dashboard"

ci "[P1] Add skeleton loading states to replace plain text loading indicators" \
"## Problem
Loading states show '—' or 'Loading...' text. Modern dashboards use skeleton screens to reduce perceived load time.

## Acceptance Criteria
- [ ] \`src/components/Skeleton.tsx\` component
- [ ] Dashboard stat cards show skeleton while loading
- [ ] Payment table rows show skeleton rows (5) while loading
- [ ] Smooth fade-in transition when data arrives" \
"enhancement,P1,ux"

ci "[P1] Add dark mode support using Tailwind \`dark:\` classes" \
"## Problem
The UI is light-mode only. Merchants working in low-light environments have no dark mode option.

## Acceptance Criteria
- [ ] Toggle in settings or nav for light/dark/system
- [ ] Preference persisted in localStorage
- [ ] All components have \`dark:\` variants
- [ ] Tailwind configured with \`darkMode: 'class'\`
- [ ] System preference detected via \`prefers-color-scheme\`" \
"enhancement,P1,ux"

ci "[P1] Implement API key generation and display in settings page" \
"## Problem
\`merchantApi.generateApiKey()\` is defined in \`api.ts\` but not surfaced in UI. Merchants need to generate API keys to use the REST API.

## Acceptance Criteria
- [ ] API Keys section in settings page
- [ ] List existing keys: prefix, scopes, created date, last used
- [ ] Generate new key dialog: scope checkboxes, name
- [ ] Key shown once in modal after generation with copy button
- [ ] Revoke key with confirmation" \
"enhancement,P1,dashboard"

ci "[P1] Add proper 404 and error pages (not-found.tsx, error.tsx)" \
"## Problem
Next.js App Router uses \`not-found.tsx\` and \`error.tsx\` for per-route error pages, but neither exists in this app. Users navigating to non-existent pages get a generic Next.js error screen.

## Acceptance Criteria
- [ ] \`src/app/not-found.tsx\` with on-brand 404 page and navigation links
- [ ] \`src/app/error.tsx\` with error boundary and 'Try again' button
- [ ] \`src/app/dashboard/error.tsx\` for dashboard-scoped errors
- [ ] Match brand styling" \
"enhancement,P1,ux"

ci "[P1] Implement toast notification system for all API actions" \
"## Problem
\`react-hot-toast\` is installed but only used in the login page. Mutations across the dashboard (create payment, save settings, revoke key) have no user feedback.

## Acceptance Criteria
- [ ] \`Toaster\` placed in root layout
- [ ] Success toast on: payment created, settings saved, key generated, webhook added
- [ ] Error toast on all API failures with message from \`err.response?.data?.message\`
- [ ] Loading toast for long operations (e.g., CSV export)" \
"enhancement,P1,ux"

ci "[P1] Add copy-to-clipboard utility with visual feedback" \
"## Problem
Payment links, API keys, Stellar addresses, and memos all need copy-to-clipboard functionality. Currently these fields have no copy affordance.

## Acceptance Criteria
- [ ] \`src/components/CopyButton.tsx\` component
- [ ] Shows checkmark for 2s after copy
- [ ] Works in all browsers (Clipboard API with fallback)
- [ ] Used on: payment link, API key, Stellar memo, deposit address" \
"enhancement,P1,ux"

ci "[P1] Add real-time unread notification badge in dashboard nav" \
"## Problem
There is no notification center in the dashboard. Merchants miss important events (settlement completed, dispute raised) unless they check their email.

## Acceptance Criteria
- [ ] Bell icon in dashboard nav with unread count badge
- [ ] Dropdown showing last 10 notifications with type, message, time
- [ ] Mark all as read button
- [ ] Notification links to relevant dashboard section
- [ ] Poll for new notifications every 30s (or WebSocket)" \
"enhancement,P1,dashboard"

ci "[P1] Improve mobile responsiveness of dashboard layout" \
"## Problem
The dashboard uses a desktop-first grid layout. On mobile (<768px), the sidebar overlaps content and stat cards overflow the viewport.

## Acceptance Criteria
- [ ] Collapsible hamburger sidebar on mobile
- [ ] Stat cards stack vertically on mobile
- [ ] Payment table scrolls horizontally on small screens
- [ ] All interactive elements meet 44px touch target minimum" \
"enhancement,P1,ux"

ci "[P1] Add WCAG 2.1 AA accessibility compliance" \
"## Problem
The app has no ARIA labels, role attributes, or keyboard navigation support. Screen reader users cannot use the merchant dashboard.

## Acceptance Criteria
- [ ] All interactive elements have accessible labels
- [ ] Focus management on modal open/close
- [ ] Keyboard navigation for all dropdowns and dialogs
- [ ] Colour contrast ratio ≥ 4.5:1 for all text
- [ ] Run axe-core in CI as part of test suite" \
"accessibility,P1,ux"

ci "[P1] Add Zustand devtools and persist hydration guard to prevent SSR mismatch" \
"## Problem
\`useAuthStore\` with \`persist\` can cause React hydration mismatches: the server renders with no auth state, the client rehydrates with stored auth, and React warns about mismatched HTML.

## Acceptance Criteria
- [ ] Wrap auth-dependent UI in a \`mounted\` guard (\`useEffect\` + state)
- [ ] Or use Next.js \`dynamic\` with \`ssr: false\` for auth-dependent components
- [ ] Add Zustand devtools in development
- [ ] Zero hydration mismatch warnings in browser console" \
"bug,P1,architecture"

ci "[P1] Implement waitlist page (/waitlist) fully" \
"## Problem
\`/waitlist\` route exists and \`waitlistApi\` is defined, but the page implementation is unknown. Public-facing waitlist is part of the go-to-market strategy.

## Acceptance Criteria
- [ ] Email, username, business name, country form
- [ ] Client-side validation
- [ ] Username availability check (debounced via \`waitlistApi.checkUsername\`)
- [ ] Success state showing position in waitlist
- [ ] SEO meta tags for the waitlist page" \
"enhancement,P1,marketing"

ci "[P1] Add \`date-fns\` locale formatting to payment dates" \
"## Problem
\`date-fns\` is installed but dates in the dashboard are formatted inconsistently. \`formatDate\` in \`utils.ts\` may not handle timezones or locales for international merchants.

## Acceptance Criteria
- [ ] Dates shown in merchant's local timezone
- [ ] Relative time for recent events: '2 minutes ago', 'Yesterday'
- [ ] Absolute date on hover tooltip: 'Oct 14, 2026 14:32 UTC'
- [ ] Date formatting consistent across all tables and cards" \
"enhancement,P1,ux"

ci "[P1] Add payment receipt page/modal after settlement" \
"## Problem
After a payment settles on \`/pay/[paymentId]\`, there is only a brief 'Payment complete' message. No receipt is shown or downloadable.

## Acceptance Criteria
- [ ] Receipt view on \`/pay/[paymentId]\` after settled status
- [ ] Shows: amount, reference, date, merchant name, Stellar transaction hash
- [ ] Print/download as PDF button
- [ ] Email receipt link if customer email provided" \
"enhancement,P1,payments"

ci "[P1] Add i18n / internationalisation support" \
"## Problem
The app is English-only. DupDub targets emerging markets (Nigeria mentioned in README) where French, Pidgin, or Hausa may be preferred.

## Acceptance Criteria
- [ ] Add \`next-intl\` or \`next-i18next\`
- [ ] Support English and French initially
- [ ] Language switcher in nav/footer
- [ ] All hardcoded strings extracted to translation files
- [ ] RTL layout support stub for future Arabic/Hausa" \
"enhancement,P1,ux"

ci "[P1] Implement dashboard search — search across payments and settlements" \
"## Problem
There is no search functionality in the dashboard. Merchants with many payments cannot find a specific payment without scrolling through all pages.

## Acceptance Criteria
- [ ] Global search input in dashboard nav
- [ ] Searches payments by reference, amount, customer email
- [ ] Keyboard shortcut: Cmd/Ctrl+K opens search
- [ ] Results grouped: Payments, Settlements
- [ ] Navigate to item on click" \
"enhancement,P1,dashboard"

ci "[P1] Add payment link sharing page — shareable URL for each payment" \
"## Problem
Merchants need to share a payment link with customers via email or WhatsApp. The \`/pay/[paymentId]\` page exists but there is no 'Share' button in the merchant dashboard.

## Acceptance Criteria
- [ ] Payment detail page shows shareable URL
- [ ] 'Share via WhatsApp/Email/Copy' buttons
- [ ] Payment link preview card (Open Graph meta for WhatsApp previews)
- [ ] Link shortener via \`NEXT_PUBLIC_APP_URL\`" \
"enhancement,P1,payments"

ci "[P1] Implement admin dashboard view at /dashboard/admin" \
"## Problem
\`/dashboard/admin\` route exists in the README architecture but no implementation exists. Internal admins have no dashboard.

## Acceptance Criteria
- [ ] Admin-only route guard (requires admin role)
- [ ] Platform-wide payment volume overview
- [ ] Pending settlement approvals list with approve/reject buttons
- [ ] Merchant list with suspend/unsuspend actions
- [ ] Alert/notification inbox" \
"enhancement,P1,dashboard"

ci "[P1] Add connection status indicator for Stellar network" \
"## Problem
If the Stellar network is degraded or the backend's Horizon connection is down, the customer payment page shows no indication. Customers think the payment is being processed when the network is down.

## Acceptance Criteria
- [ ] Poll backend \`GET /health\` on \`/pay/[paymentId]\` page
- [ ] Show 'Network degraded — payments may be delayed' banner if Stellar health check fails
- [ ] Dashboard shows Stellar network status in footer
- [ ] Link to status page" \
"enhancement,P1,payments"

ci "[P1] Add payment expiry countdown timer on /pay/[paymentId]" \
"## Problem
Customers see no countdown showing when the payment request expires. If they wait too long, the payment silently expires with no warning.

## Acceptance Criteria
- [ ] Countdown timer showing time remaining until \`expiresAt\`
- [ ] Warning state: amber colour when < 5 minutes remain
- [ ] Critical state: red when < 1 minute remains
- [ ] 'Payment expired' state when countdown reaches zero
- [ ] Auto-refresh to show expired status without user action" \
"enhancement,P1,payments"

ci "[P1] Lazy-load recharts on analytics page to reduce initial bundle" \
"## Problem
\`recharts\` is a large library (~500KB). It is likely loaded on every page because it's imported at the top level. This increases the LCP time for all pages.

## Acceptance Criteria
- [ ] Use \`next/dynamic\` with \`ssr: false\` for recharts components
- [ ] Measure bundle size before and after with \`next-bundle-analyzer\`
- [ ] Analytics page hydrates without impact on other routes
- [ ] LCP score improves (target < 2.5s on 4G)" \
"performance,P1,architecture"

# ── P2 MEDIUM (45) ───────────────────────────────────────────────────────────

ci "[P2] Add storybook for UI component development and documentation" \
"## Problem
There are no isolated component tests or visual documentation. New developers cannot preview UI components without running the full app.

## Acceptance Criteria
- [ ] Storybook 8+ configured for Next.js
- [ ] Stories for: Button, Input, Card, Badge, Modal, Skeleton, CopyButton
- [ ] Deployed to Chromatic for visual regression testing
- [ ] README section on component library" \
"documentation,P2,architecture"

ci "[P2] Add Playwright E2E test suite" \
"## Problem
No E2E tests exist. Critical user flows (login → create payment → share link) can break silently.

## Acceptance Criteria
- [ ] Playwright installed and configured
- [ ] Test: merchant registration and login
- [ ] Test: create payment, verify QR code shown, copy link
- [ ] Test: view settlements list
- [ ] CI runs E2E tests against a staging deployment" \
"testing,P2,architecture"

ci "[P2] Add bundle analyzer and enforce bundle size budget" \
"## Problem
No bundle analysis is performed. Large third-party dependencies could inflate the JavaScript bundle, harming performance.

## Acceptance Criteria
- [ ] \`@next/bundle-analyzer\` added as devDependency
- [ ] \`npm run analyze\` script
- [ ] Current bundle documented in README
- [ ] CI fails if main bundle exceeds 300KB gzipped" \
"performance,P2,architecture"

ci "[P2] Add comprehensive Open Graph and Twitter Card meta tags" \
"## Problem
The landing page and payment pages have no Open Graph metadata. Sharing a payment link on WhatsApp/Slack shows no preview.

## Acceptance Criteria
- [ ] \`src/app/layout.tsx\` — site-wide OG meta
- [ ] \`/pay/[paymentId]\` — dynamic OG: 'Pay DupDub – \$X USD'
- [ ] Twitter Card \`summary_large_image\`
- [ ] Canonical URLs
- [ ] Test with Facebook Debugger and Twitter Card Validator" \
"enhancement,P2,marketing"

ci "[P2] Add sitemap.xml and robots.txt for SEO" \
"## Problem
No \`sitemap.xml\` or \`robots.txt\` exists. Search engines index the dashboard behind auth, wasting crawl budget.

## Acceptance Criteria
- [ ] \`src/app/sitemap.ts\` — Next.js sitemap route for public pages
- [ ] \`src/app/robots.ts\` — disallow dashboard routes
- [ ] Verify with Google Search Console
- [ ] Add structured data (JSON-LD) for the landing page" \
"enhancement,P2,marketing"

ci "[P2] Implement \`usePaymentStatus\` custom hook to centralise polling logic" \
"## Problem
Payment status polling logic is inline in \`/pay/[paymentId]/page.tsx\`. This makes it hard to test, reuse, or replace with WebSocket later.

## Acceptance Criteria
- [ ] \`src/hooks/usePaymentStatus.ts\` — accepts paymentId, returns \`{ payment, loading, error }\`
- [ ] Handles polling interval, cleanup, and abort
- [ ] Easy to swap polling for WebSocket subscription later
- [ ] Unit tested with mocked Axios" \
"quality,P2,architecture"

ci "[P2] Add Zustand slice pattern — split auth store from UI state" \
"## Problem
All state (auth + any future UI state) is in one Zustand store. As the app grows, this becomes hard to maintain.

## Acceptance Criteria
- [ ] \`src/lib/stores/auth.store.ts\` — auth state only
- [ ] \`src/lib/stores/ui.store.ts\` — dashboard UI state (selected tab, modal open, etc.)
- [ ] Existing \`useAuthStore\` import alias maintained for backward compat
- [ ] Devtools enabled for both stores" \
"quality,P2,architecture"

ci "[P2] Add \`axios-retry\` for transient API failures" \
"## Problem
A single network blip causes API calls to fail immediately. Critical operations (payment status polling) should retry on 5xx or network errors.

## Acceptance Criteria
- [ ] \`axios-retry\` configured on the Axios instance
- [ ] 3 retries with exponential backoff for 5xx and network errors
- [ ] Do NOT retry 4xx errors (bad request, not found)
- [ ] Retry count logged in development" \
"enhancement,P2,architecture"

ci "[P2] Add keyboard shortcuts for common dashboard actions" \
"## Problem
Power users (merchants processing many payments) benefit from keyboard shortcuts. None exist today.

## Acceptance Criteria
- [ ] \`N\` — new payment
- [ ] \`Cmd/Ctrl+K\` — open search
- [ ] \`Esc\` — close modal
- [ ] \`/\` — focus search input
- [ ] Keyboard shortcut cheatsheet in help menu" \
"enhancement,P2,ux"

ci "[P2] Implement help documentation / FAQ section in dashboard" \
"## Problem
Merchants have no in-app help. They must email support for basic questions like 'How do I share a payment link?'

## Acceptance Criteria
- [ ] \`/dashboard/help\` route with searchable FAQ
- [ ] FAQ items: How payments work, Stellar memo importance, Settlement timeline, API key usage
- [ ] Intercom/chat widget integration placeholder
- [ ] Link to external docs site" \
"documentation,P2,dashboard"

ci "[P2] Add \`next/image\` for all image assets — remove raw \`<img>\` tags" \
"## Problem
Any raw \`<img>\` elements bypass Next.js image optimisation (WebP conversion, lazy loading, size hints). This affects Core Web Vitals.

## Acceptance Criteria
- [ ] Replace all \`<img>\` with \`next/image\`
- [ ] Set explicit width/height or fill props on all images
- [ ] Add allowed image domains to \`next.config.js\`
- [ ] Verify LCP improvement" \
"performance,P2,architecture"

ci "[P2] Add currency formatting utility and use consistently" \
"## Problem
\`formatUsd\` in \`utils.ts\` formats USD but DupDub settlements are in NGN. There is no \`formatNgn\` utility. Currency display is inconsistent across pages.

## Acceptance Criteria
- [ ] \`formatCurrency(amount, currency)\` utility using \`Intl.NumberFormat\`
- [ ] Support USD, NGN, GBP, EUR
- [ ] Merchant's preferred display currency from profile
- [ ] Applied consistently: dashboard stats, payment table, settlement table" \
"enhancement,P2,ux"

ci "[P2] Add form field for payment metadata in create-payment form" \
"## Problem
The backend supports arbitrary \`metadata\` JSON on payments (order ID, product name, etc.) but the frontend payment creation form has no metadata field.

## Acceptance Criteria
- [ ] Dynamic key-value pair input in payment creation form
- [ ] Add/remove metadata fields
- [ ] Metadata serialised as JSON before submission
- [ ] Shown in payment detail view" \
"enhancement,P2,payments"

ci "[P2] Implement CSV export for payments table" \
"## Problem
Merchants need to export payment data for accounting. No export button exists.

## Acceptance Criteria
- [ ] 'Export CSV' button on payments page
- [ ] Exports all filtered/searched payments (not just current page)
- [ ] Columns: reference, amount, status, date, customer email, Stellar memo
- [ ] Show loading state during export
- [ ] Trigger browser download" \
"enhancement,P2,dashboard"

ci "[P2] Add two-factor authentication setup flow in settings" \
"## Problem
Once the backend implements 2FA, the frontend needs a setup flow in settings.

## Acceptance Criteria
- [ ] '2FA' section in settings page
- [ ] Show QR code from backend TOTP endpoint
- [ ] Verify 6-digit code before enabling
- [ ] Download backup codes as text file
- [ ] Disable 2FA with password confirmation" \
"security,P2,auth"

ci "[P2] Add payment analytics funnel chart" \
"## Problem
The analytics page needs a funnel chart showing conversion from created → confirmed → settled payments.

## Acceptance Criteria
- [ ] Funnel chart using recharts FunnelChart
- [ ] Stages: Created, Confirmed, Settling, Settled
- [ ] Percentage shown at each stage
- [ ] Date range filter
- [ ] Compare to previous period toggle" \
"enhancement,P2,analytics"

ci "[P2] Add top-merchants panel for admin dashboard" \
"## Problem
Admin dashboard needs visibility into top-performing merchants by payment volume.

## Acceptance Criteria
- [ ] Table: rank, merchant name, total volume, payment count, avg order value
- [ ] Period selector: 7d, 30d, 90d
- [ ] Click merchant row to view merchant detail
- [ ] Export as CSV" \
"enhancement,P2,dashboard"

ci "[P2] Implement confirmation dialog component" \
"## Problem
Destructive actions (delete webhook, revoke API key) have no confirmation. Users can accidentally perform irreversible actions.

## Acceptance Criteria
- [ ] \`src/components/ConfirmDialog.tsx\` — reusable modal with title, message, confirm/cancel
- [ ] Used for: delete webhook, revoke API key, suspend merchant
- [ ] Requires typing confirmation text for irreversible actions
- [ ] Focus trap and keyboard dismissal" \
"quality,P2,ux"

ci "[P2] Add \`next-pwa\` Progressive Web App support" \
"## Problem
The README mentions PWA as a roadmap item. Merchants in mobile-first markets (Nigeria) benefit from installable PWA.

## Acceptance Criteria
- [ ] \`next-pwa\` configured with service worker
- [ ] Web app manifest with icons, theme color, display mode
- [ ] Offline fallback page
- [ ] Install prompt on mobile
- [ ] Push notification permission prompt" \
"enhancement,P2,ux"

ci "[P2] Add payment QR code download button" \
"## Problem
Merchants printing payment instructions need to download the QR code as a PNG or SVG. No download option exists on the QR code component.

## Acceptance Criteria
- [ ] 'Download QR' button below the QR code
- [ ] Exports as SVG (vector, scalable for print)
- [ ] Optional PNG export at 512x512
- [ ] File named \`payment-[reference].svg\`" \
"enhancement,P2,payments"

ci "[P2] Add merchant onboarding checklist on first login" \
"## Problem
New merchants have no guided onboarding. They see the empty dashboard and don't know what to do next.

## Acceptance Criteria
- [ ] Onboarding banner shown if merchant has 0 payments
- [ ] Checklist: Complete profile, Add bank account, Create first payment, Add webhook
- [ ] Each step links to relevant page
- [ ] Dismissible after all steps complete
- [ ] Progress tracked in localStorage" \
"enhancement,P2,ux"

ci "[P2] Add connection status indicator and offline mode" \
"## Problem
If the user loses internet connection, API calls fail silently. The dashboard shows stale data with no network status indication.

## Acceptance Criteria
- [ ] Use \`navigator.onLine\` and \`online/offline\` events
- [ ] 'You are offline' banner when connection lost
- [ ] Disable form submissions when offline
- [ ] Auto-retry failed requests when connection restored" \
"enhancement,P2,ux"

ci "[P2] Add print stylesheet for payment receipt and settlement records" \
"## Problem
Merchants and customers printing receipts or settlement records see the full browser UI (nav, sidebar). A print stylesheet hides irrelevant elements.

## Acceptance Criteria
- [ ] \`@media print\` styles in globals.css
- [ ] Hide nav, sidebar, buttons when printing
- [ ] Show only receipt/settlement data
- [ ] Test in Chrome and Firefox print preview" \
"enhancement,P2,ux"

ci "[P2] Implement webhook event log in webhook management page" \
"## Problem
Merchants cannot see webhook delivery history. If a webhook failed, they don't know why.

## Acceptance Criteria
- [ ] Per-webhook delivery log: timestamp, event type, status (delivered/failed), HTTP response code
- [ ] Retry failed delivery button
- [ ] Last 50 deliveries shown with pagination
- [ ] Filter by event type or status" \
"enhancement,P2,dashboard"

ci "[P2] Add Vercel Analytics and Speed Insights" \
"## Problem
There are no analytics on how the landing page or payment pages perform for real users.

## Acceptance Criteria
- [ ] \`@vercel/analytics\` and \`@vercel/speed-insights\` installed
- [ ] \`<Analytics />\` and \`<SpeedInsights />\` in root layout
- [ ] Track custom events: payment QR viewed, Freighter payment initiated, waitlist signup
- [ ] Dashboard in Vercel project" \
"observability,P2,architecture"

ci "[P2] Add \`@tanstack/react-query\` for server state management" \
"## Problem
Data fetching is done with raw \`useEffect + useState\` patterns. This leads to inconsistent loading/error states, no caching, and no automatic refetch.

## Acceptance Criteria
- [ ] Install and configure \`@tanstack/react-query\`
- [ ] Migrate dashboard page data fetching to \`useQuery\` hooks
- [ ] \`useMutation\` for create payment, save settings
- [ ] Query invalidation on mutations
- [ ] Devtools in development" \
"quality,P2,architecture"

ci "[P2] Add password strength meter to registration form" \
"## Problem
The registration form has a password field with no strength indicator. Merchants create weak passwords with no feedback.

## Acceptance Criteria
- [ ] Password strength meter: Weak / Fair / Strong / Very Strong
- [ ] Requirements checklist: 8+ chars, uppercase, lowercase, number, symbol
- [ ] Show/hide password toggle
- [ ] Confirm password field with match validation" \
"enhancement,P2,auth"

ci "[P2] Add merchant avatar / logo upload" \
"## Problem
Merchant profiles have no visual identity. The business name appears as plain text in the dashboard nav. An avatar adds trust to payment pages.

## Acceptance Criteria
- [ ] Avatar upload in settings page
- [ ] Accepts JPG, PNG, WebP up to 2MB
- [ ] Cropped to 1:1 ratio before upload
- [ ] Shown in dashboard nav and payment page header" \
"enhancement,P2,dashboard"

ci "[P2] Implement rate-limited API calls with request deduplication" \
"## Problem
The dashboard makes multiple concurrent API calls on mount (\`Promise.all\`). Fast navigation can trigger duplicate requests for the same data.

## Acceptance Criteria
- [ ] Deduplicate in-flight requests with React Query
- [ ] AbortController on navigation
- [ ] Max concurrency of 3 API calls
- [ ] Debounce search inputs (300ms)" \
"performance,P2,architecture"

ci "[P2] Add admin settlements approval page" \
"## Problem
The backend implements a large-settlement approval workflow, but there is no frontend for admins to approve/reject these settlements.

## Acceptance Criteria
- [ ] \`/dashboard/admin/settlements\` page listing pending approval settlements
- [ ] Settlement detail: merchant, amount, fee, net, Stellar reference
- [ ] Approve button: calls \`POST /admin/settlements/:id/approve\`
- [ ] Reject button with reason input
- [ ] Audit trail shown per settlement" \
"enhancement,P2,dashboard"

ci "[P2] Add merchant AML flag visibility in admin dashboard" \
"## Problem
Admins cannot see AML flags from the frontend. AML review happens via direct database access.

## Acceptance Criteria
- [ ] \`/dashboard/admin/aml\` page listing open AML flags
- [ ] Flag detail: merchant, payment, flag reason, raised at
- [ ] Mark as reviewed button
- [ ] Filter by status: OPEN, UNDER_REVIEW, RESOLVED, ESCALATED" \
"enhancement,P2,dashboard"

ci "[P2] Improve landing page with pricing section" \
"## Problem
The landing page has no pricing information. Merchants evaluating DupDub cannot see the fee structure without signing up.

## Acceptance Criteria
- [ ] Pricing section with fee tiers (1.5% standard, lower for volume)
- [ ] Comparison table vs traditional payment processors
- [ ] FAQ accordion with common questions
- [ ] CTA in pricing section" \
"enhancement,P2,marketing"

ci "[P2] Add payment link expiry handling in customer flow" \
"## Problem
If a customer opens an expired payment link, they see a generic error. There should be a clear expired state with instructions to contact the merchant.

## Acceptance Criteria
- [ ] Dedicated expired payment UI (not an error)
- [ ] 'This payment has expired' message with merchant contact info
- [ ] 'Create new payment' link for merchant
- [ ] OG preview for expired link shows 'Payment Expired'" \
"enhancement,P2,payments"

ci "[P2] Add \`react-hook-form\` and \`zod\` for all forms" \
"## Problem
Forms use manual state management (\`useState({ email: '', password: '' })\`). This pattern is error-prone and difficult to validate.

## Acceptance Criteria
- [ ] Install \`react-hook-form\` and \`zod\`
- [ ] Migrate login, register, create-payment forms
- [ ] Inline field-level error messages
- [ ] \`zodResolver\` for schema validation
- [ ] Loading state on submit button" \
"quality,P2,architecture"

ci "[P2] Add time-series payment volume chart to dashboard" \
"## Problem
The dashboard shows aggregate stats but no time-series chart. Merchants cannot see whether payment volume is trending up or down.

## Acceptance Criteria
- [ ] Line chart: daily payment volume (USD) over last 30 days
- [ ] Overlay: number of payments (secondary axis)
- [ ] Tooltip with exact values on hover
- [ ] Toggle to compare to previous period
- [ ] Recharts ResponsiveContainer for mobile" \
"enhancement,P2,analytics"

ci "[P2] Add empty state illustrations for dashboard sections" \
"## Problem
Empty dashboard sections show plain text like 'No payments yet'. Empty states with illustrations and CTAs improve the new-user experience.

## Acceptance Criteria
- [ ] Empty state component for payments list (with 'Create your first payment' CTA)
- [ ] Empty state for settlements (with 'Settlements appear after your first payment' message)
- [ ] Empty state for webhooks
- [ ] SVG illustrations (inline, no external requests)" \
"enhancement,P2,ux"

# ── P3 LOW (35) ──────────────────────────────────────────────────────────────

ci "[P3] Add ESLint rules: no-console, no-explicit-any, import/order" \
"## Problem
\`.eslintrc.json\` uses minimal Next.js defaults. \`console.log\` and explicit \`any\` are allowed in production code.

## Acceptance Criteria
- [ ] Add \`no-console\` rule (error in production, warn in dev)
- [ ] Add \`@typescript-eslint/no-explicit-any\` rule
- [ ] Add \`import/order\` rule for consistent import grouping
- [ ] CI fails on any ESLint error" \
"quality,P3,architecture"

ci "[P3] Add Prettier and enforce consistent code formatting" \
"## Problem
No Prettier config exists. Code style is inconsistent across files.

## Acceptance Criteria
- [ ] \`.prettierrc\` with: singleQuote, tabWidth 2, trailingComma es5
- [ ] \`format\` npm script
- [ ] Pre-commit hook via lint-staged
- [ ] CI formatting check" \
"quality,P3,architecture"

ci "[P3] Document component architecture in README" \
"## Problem
README covers setup and deployment but not the component architecture, file naming conventions, or patterns used.

## Acceptance Criteria
- [ ] README section: Component Architecture
- [ ] Explain: page components vs shared components vs hooks vs utils
- [ ] File naming convention (kebab-case for files, PascalCase for components)
- [ ] State management patterns (Zustand for global, useQuery for server)" \
"documentation,P3,architecture"

ci "[P3] Add Makefile for common development commands" \
"## Problem
Developers must remember multiple npm commands. A Makefile with aliases improves DX.

## Acceptance Criteria
- [ ] \`make dev\` — start dev server
- [ ] \`make build\` — production build
- [ ] \`make test\` — run all tests
- [ ] \`make lint\` — run ESLint + Prettier check
- [ ] \`make analyze\` — bundle analysis" \
"documentation,P3,architecture"

ci "[P3] Add \`CONTRIBUTING.md\` with development setup guide" \
"## Problem
No contributing guide exists. External contributors and new team members have no starting point.

## Acceptance Criteria
- [ ] Prerequisites: Node 18+, backend running, env vars
- [ ] Local dev setup steps
- [ ] Branch naming convention
- [ ] PR checklist
- [ ] Code review expectations" \
"documentation,P3,architecture"

ci "[P3] Add GitHub Actions CI workflow" \
"## Problem
No \`.github/workflows/\` exists in the frontend repo. There is no automated lint, type-check, or test on PRs.

## Acceptance Criteria
- [ ] \`.github/workflows/ci.yml\`
- [ ] Runs: \`tsc --noEmit\`, \`eslint\`, \`next build\`, \`jest\`
- [ ] Triggered on PR and push to main
- [ ] Build status badge in README" \
"devops,P3,architecture"

ci "[P3] Add Vercel deployment preview URLs to PRs" \
"## Problem
PRs have no preview deployment, making it hard to review UI changes without checking out locally.

## Acceptance Criteria
- [ ] Vercel project configured for the repo
- [ ] Preview URL posted to PR as GitHub comment
- [ ] Preview uses \`NEXT_PUBLIC_API_URL\` pointing to staging backend
- [ ] README includes deployment badge" \
"devops,P3,architecture"

ci "[P3] Add \`next/font\` for optimised web font loading" \
"## Problem
If any custom fonts are used (or planned), raw \`<link>\` font tags block render. \`next/font\` preloads and self-hosts fonts.

## Acceptance Criteria
- [ ] Replace any font \`<link>\` tags with \`next/font/google\` or \`next/font/local\`
- [ ] Swap display set to \`swap\`
- [ ] CSS variable for font family in tailwind config
- [ ] Measure CLS improvement" \
"performance,P3,architecture"

ci "[P3] Add light/dark mode logo and favicon variants" \
"## Problem
A single favicon is served regardless of system colour scheme. On dark OS themes, a dark favicon becomes invisible.

## Acceptance Criteria
- [ ] SVG favicon with \`prefers-color-scheme\` media query
- [ ] Dark and light logo variants
- [ ] Apple touch icon (180x180)
- [ ] Manifest icons for PWA" \
"enhancement,P3,ux"

ci "[P3] Add Terms of Service and Privacy Policy pages" \
"## Problem
The landing page footer links to Terms/Privacy but no such pages exist. This is a legal requirement for launching.

## Acceptance Criteria
- [ ] \`/legal/terms\` — Terms of Service
- [ ] \`/legal/privacy\` — Privacy Policy
- [ ] GDPR compliance section in Privacy Policy
- [ ] Link in registration form and footer
- [ ] Last updated date visible" \
"documentation,P3,marketing"

ci "[P3] Add cookie consent banner (GDPR)" \
"## Problem
Any analytics or tracking requires a GDPR-compliant cookie consent banner for EU users.

## Acceptance Criteria
- [ ] Cookie banner on first visit
- [ ] Accept/Reject all buttons
- [ ] Manage preferences link
- [ ] Preference stored in localStorage for 1 year
- [ ] Analytics only loaded after consent" \
"compliance,P3,ux"

ci "[P3] Improve landing page hero with animated payment flow illustration" \
"## Problem
The hero section has text only. A visual showing the payment flow (merchant QR → customer wallet → bank account) would improve conversion.

## Acceptance Criteria
- [ ] SVG animation showing the 3-step flow
- [ ] Animates on scroll-into-view
- [ ] Accessible: \`prefers-reduced-motion\` disables animation
- [ ] Does not increase LCP (lazy loaded)" \
"enhancement,P3,marketing"

ci "[P3] Add integration status page at /status" \
"## Problem
There is no public status page. When DupDub is down, merchants have no place to check service status.

## Acceptance Criteria
- [ ] \`/status\` page fetching \`GET /health\` from backend
- [ ] Shows: API, Stellar Network, Settlement Queue status
- [ ] Incident history (last 7 days)
- [ ] Subscribe to status email updates
- [ ] Links to monitoring/statuspage (Better Uptime already configured in stellar repo)" \
"enhancement,P3,ux"

ci "[P3] Add payment success animation on /pay/[paymentId]" \
"## Problem
When a payment settles, the status changes to 'settled' with a static green checkmark. A brief celebration animation improves customer confidence.

## Acceptance Criteria
- [ ] Confetti animation or checkmark lottie on settled status
- [ ] Animation plays once (not looping)
- [ ] Accessible: respects \`prefers-reduced-motion\`
- [ ] Less than 50KB additional bundle" \
"enhancement,P3,payments"

ci "[P3] Add keyboard navigation for payment list table" \
"## Problem
The payments table is not keyboard-navigable. Screen reader and keyboard-only users cannot browse payment records.

## Acceptance Criteria
- [ ] Arrow keys navigate rows
- [ ] Enter opens payment detail
- [ ] \`Tab\` focuses action buttons within a row
- [ ] Row focus style visible
- [ ] Screen reader announces row content" \
"accessibility,P3,ux"

ci "[P3] Add custom 500 error page" \
"## Problem
Server errors show Next.js default 500 page. Merchants see a generic error with no brand consistency.

## Acceptance Criteria
- [ ] \`src/app/global-error.tsx\` — top-level error boundary
- [ ] On-brand design matching 404 page
- [ ] Report to Sentry on render
- [ ] 'Go to Dashboard' and 'Reload' buttons" \
"enhancement,P3,ux"

ci "[P3] Add payment amount range filter to payments table" \
"## Problem
Merchants with many payments need to filter by amount range (e.g., find all payments > \$100).

## Acceptance Criteria
- [ ] Min/max amount inputs in payments filter panel
- [ ] Applied alongside status and search filters
- [ ] URL params updated for shareable filtered views
- [ ] Clear all filters button" \
"enhancement,P3,dashboard"

ci "[P3] Add copy Stellar memo button on payment detail" \
"## Problem
The payment detail shows the Stellar memo but no copy button. Support staff must manually select and copy the memo text.

## Acceptance Criteria
- [ ] Copy button next to Stellar memo field
- [ ] Copy button next to Stellar deposit address
- [ ] 'Copied!' tooltip for 2s after click
- [ ] Works on mobile (touch copy)" \
"enhancement,P3,payments"

ci "[P3] Add payment reference QR code to merchant receipt" \
"## Problem
When merchants print a payment confirmation, there is no QR code on the receipt. A QR linking to the payment page would allow quick re-access.

## Acceptance Criteria
- [ ] QR code on printed receipt pointing to \`/pay/[paymentId]\`
- [ ] Only shown in print view
- [ ] Hidden in screen view to save space" \
"enhancement,P3,payments"

ci "[P3] Add \`focus-visible\` styles for keyboard navigation" \
"## Problem
Tailwind's default focus styles are removed by \`focus:outline-none\` in some components. Keyboard users cannot see which element is focused.

## Acceptance Criteria
- [ ] All interactive elements have visible \`focus-visible\` styles
- [ ] Tailwind plugin \`@tailwindcss/forms\` for consistent input focus
- [ ] Tested with Tab key navigation through all forms and tables" \
"accessibility,P3,ux"

ci "[P3] Add merchant onboarding video tutorial link" \
"## Problem
New merchants have no video walkthrough showing how to get from registration to first payment.

## Acceptance Criteria
- [ ] Video link on onboarding checklist
- [ ] Embedded tutorial modal in dashboard help section
- [ ] Link to YouTube playlist or Loom recording
- [ ] Transcript available for accessibility" \
"documentation,P3,ux"

ci "[P3] Add \`rel='noopener noreferrer'\` to all external links" \
"## Problem
External links (\`target='_blank'\`) without \`rel='noopener noreferrer'\` allow the target page to access \`window.opener\`.

## Acceptance Criteria
- [ ] Audit all external links in the codebase
- [ ] Add \`rel='noopener noreferrer'\` to all \`target='_blank'\` links
- [ ] ESLint rule \`jsx-a11y/anchor-has-content\` to catch future regressions" \
"security,P3,architecture"

ci "[P3] Remove hardcoded '© 2025 DupDub' in footer — should use current year" \
"## Problem
\`src/app/page.tsx\` has \`© 2025 DupDub\` hardcoded. This becomes incorrect on January 1, 2026.

## Acceptance Criteria
- [ ] Replace with \`© \${new Date().getFullYear()} DupDub\`
- [ ] Applied consistently in all footers
- [ ] Server-rendered (not hydration-dependent)" \
"quality,P3,ux"

ci "[P3] Add payment amount in XLM to payment detail" \
"## Problem
The customer payment page shows amount in USD only. Some customers want to see the equivalent XLM amount before sending.

## Acceptance Criteria
- [ ] Show 'Equivalent: X XLM' below USD amount
- [ ] Refresh rate every 30s (XLM rate is volatile)
- [ ] Warning if XLM rate is stale (> 2 minutes)" \
"enhancement,P3,payments"

ci "[P3] Add merchant bank account UI in settings" \
"## Problem
Once the backend supports multiple bank accounts per merchant, the settings page needs a UI to add and manage them.

## Acceptance Criteria
- [ ] Bank Accounts section in settings
- [ ] Add account form: bank name, account number, routing number, currency
- [ ] Set default account button
- [ ] Remove account with confirmation" \
"enhancement,P3,dashboard"

ci "[P3] Add changelog page at /changelog" \
"## Problem
Merchants integrating via API need to know when the platform changes. No changelog exists.

## Acceptance Criteria
- [ ] \`/changelog\` route with version history
- [ ] Entries fetched from a static markdown file or CMS
- [ ] RSS feed at \`/changelog/feed.xml\`
- [ ] 'What's new' banner in dashboard linking to latest entry" \
"documentation,P3,marketing"

ci "[P3] Add rate limiting indicator in API key settings" \
"## Problem
Merchants don't know what their API rate limits are until they hit them. The settings page should show current rate limit and usage.

## Acceptance Criteria
- [ ] Rate limit display in API key settings: X requests/min, current usage
- [ ] Progress bar showing usage vs limit
- [ ] Link to docs on rate limiting
- [ ] Email alert when 80% of limit reached" \
"enhancement,P3,dashboard"

ci "[P3] Add mobile deep link support for payment flow" \
"## Problem
On mobile, clicking the payment QR link should open the Stellar wallet app directly (deep link). Currently only QR scanning works on mobile.

## Acceptance Criteria
- [ ] 'Open in Lobstr' button on mobile /pay page
- [ ] 'Open in Solar' button on mobile
- [ ] Deep link uses \`lobstr://\` and \`solar://\` URI schemes
- [ ] Fall back to App Store / Play Store link if app not installed" \
"enhancement,P3,payments"

ci "[P3] Add \`@vercel/og\` dynamic OG image generation for payment pages" \
"## Problem
Payment pages need dynamic OG images showing the amount and merchant name for rich WhatsApp/Slack previews.

## Acceptance Criteria
- [ ] \`src/app/pay/[paymentId]/opengraph-image.tsx\`
- [ ] Generates: 'Pay DupDub — \$50.00 USD to [Merchant Name]'
- [ ] Brand colours and DupDub logo
- [ ] 1200x630 size
- [ ] Cached with proper revalidation" \
"enhancement,P3,marketing"

ci "[P3] Improve waitlist confirmation page" \
"## Problem
After joining the waitlist, users likely see a basic success message. A proper confirmation page with social sharing improves viral growth.

## Acceptance Criteria
- [ ] Waitlist confirmation page with: 'You're on the list!' message, position number
- [ ] Share on Twitter/X button with pre-filled text
- [ ] Share via WhatsApp
- [ ] Referral link to move up the waitlist" \
"enhancement,P3,marketing"

ci "[P3] Add sitemap for dynamic payment pages" \
"## Problem
\`/pay/[paymentId]\` pages are dynamically generated. They don't need to be indexed, but the sitemap should explicitly exclude them.

## Acceptance Criteria
- [ ] \`robots.ts\` disallows \`/pay/*\` routes
- [ ] Public pages (landing, waitlist, /status) included in sitemap
- [ ] Dashboard routes explicitly disallowed
- [ ] Verify with Google Search Console" \
"enhancement,P3,marketing"

ci "[P3] Add automated Lighthouse CI checks" \
"## Problem
No automated performance, accessibility, or SEO auditing exists for the frontend.

## Acceptance Criteria
- [ ] \`lighthouse-ci\` in GitHub Actions
- [ ] Run on landing page and /pay/[paymentId]
- [ ] Thresholds: performance > 90, accessibility > 90, SEO > 90
- [ ] Report posted to PR as GitHub comment" \
"quality,P3,architecture"

echo "Done! 125 issues created for dupdap-frontend."

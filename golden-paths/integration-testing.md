# Golden Path: Integration Testing (Playwright + Page Object Model)

Standard architecture for integration testing Vue MFE applications using Playwright with the Page Object Model pattern.

**Use when:** Building integration tests for Vue MFE applications, end-to-end user flows, API-backed UI validation.

**Reference implementations:** finance (integration/)

---

## Project Structure

```
integration/
├── credentials/
│   ├── credentials.ts
│   ├── credentialsTypes.ts
│   └── credential-manager.ts
├── fixtures/
│   ├── pages/
│   │   └── pages.ts
│   ├── services/
│   │   └── services.ts
│   └── fixtures.ts
├── helpers/                 # Shared utilities
│   ├── setup-helper.ts
│   └── storage-state-paths.ts
├── pages/
│   ├── {feature}/
│   │   └── {Feature}Page.ts
│   ├── common/
│   │   └── {Component}Mixin.ts
│   └── login.page.ts
├── services/
│   ├── auth/
│   │   └── authService.ts
│   └── services.ts
├── storageState/
│   └── *.json               # Git-ignored
├── tests/
│   ├── authentication/
│   │   └── *.setup.ts
│   ├── setup/
│   │   ├── storageStates.ts
│   │   └── setup-helper.ts
│   └── integration-tests/
│       └── **/*.spec.ts
├── playwright.config.ts
└── tsconfig.json
```

---

## Layer Responsibilities

### pages/ (Page Object Model)

Each page object represents a single page or component. Locators are readonly; actions encapsulate interactions.

```typescript
import { Page, Locator } from '@playwright/test';

export class LoginPage {
  readonly page: Page;
  readonly usernameInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;

  constructor(page: Page) {
    this.page = page;
    this.usernameInput = page.locator('[data-test-id="username"]');
    this.passwordInput = page.locator('[data-test-id="password"]');
    this.submitButton = page.getByRole('button', { name: 'Sign In' });
    this.errorMessage = page.locator('[data-test-id="login-error"]');
  }

  async goto(url = '/') {
    await this.page.goto(url);
  }

  async login(username: string, password: string) {
    await this.usernameInput.fill(username);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
    await this.page.waitForURL('**/dashboard/**');
  }

  async getErrorMessage(): Promise<string | null> {
    return this.errorMessage.isVisible()
      ? await this.errorMessage.textContent()
      : null;
  }
}
```

**Rules:**
- Prefer `[data-test-id="..."]` over CSS classes or IDs
- Use `getByRole`, `getByLabel`, `getByText` when data-test-id unavailable
- No assertions in page objects; keep assertions in tests
- Define locators as readonly properties
- Wait for response or URL instead of `waitForTimeout`

### pages/ (Component Mixins)

Mixin classes for shared UI components (toasts, modals, tabs).

```typescript
import { Page, Locator } from '@playwright/test';

export class ToastMixin {
  readonly page: Page;
  readonly notificationTitle: Locator;
  readonly notificationMessage: Locator;

  constructor(page: Page) {
    this.page = page;
    this.notificationTitle = page.locator('[data-test-id="toast-title"]');
    this.notificationMessage = page.locator('[data-test-id="toast-message"]');
  }

  async waitForToastHidden() {
    await this.page.locator('[data-test-id="toast-container"]').waitFor({ state: 'hidden' });
  }
}
```

### fixtures/pages/ (Page Aggregator)

```typescript
import { Browser, BrowserContext, Page } from '@playwright/test';
import { LoginPage } from '../pages/login.page';
import { DashboardPage } from '../pages/dashboard/dashboard.page';

export class Pages {
  readonly page: Page;
  readonly browser: Browser;
  readonly context: BrowserContext;
  readonly loginPage: LoginPage;
  readonly dashboardPage: DashboardPage;

  constructor(browser: Browser, context: BrowserContext, page: Page) {
    this.page = page;
    this.browser = browser;
    this.context = context;
    this.loginPage = new LoginPage(page);
    this.dashboardPage = new DashboardPage(page);
  }
}
```

### services/ (API Service Layer)

Service classes encapsulate API operations for setup, teardown, and validation.

```typescript
import { APIRequest } from '@playwright/test';

export class AuthService {
  readonly request: APIRequest;

  constructor(request: APIRequest) {
    this.request = request;
  }

  async getSuperAdminToken(): Promise<string> {
    const authProvider = await AuthProvider.monolithAuthProvider(this.request);
    const credentials = await getSuperAdminCredentials();
    return authProvider.getUserToken(credentials);
  }
}

export class Services {
  readonly request: APIRequest;
  readonly authService: AuthService;

  constructor(request: APIRequest) {
    this.request = request;
    this.authService = new AuthService(this.request);
  }
}
```

**Rules:**
- One service per domain
- Explicit return types
- Pass token as parameter for authenticated calls
- Create and dispose request context per call

### credentials/ (Credential Management)

```typescript
export interface Credential {
  username: string;
  password: string;
}

export async function getSuperAdminCredentials(): Promise<Credential> {
  const password = await accessSecretsFromPath(SECRETS_PATH, 'SUPER_ADMIN_PASSWORD');
  return {
    username: 'admin@example.com',
    password,
  };
}
```

```typescript
export class CredentialManager {
  readonly superAdmin: Promise<Credential>;

  constructor() {
    this.superAdmin = getSuperAdminCredentials();
  }
}
```

**Rules:**
- Never hardcode credentials
- Retrieve asynchronously from secrets manager or env
- Use credentials fixture for test access

### fixtures/fixtures.ts

```typescript
import { test as base, request } from '@playwright/test';
import { Pages } from './pages/pages';
import { Services } from '../services/services';
import { CredentialManager } from '../credentials/credential-manager';

type CustomFixture = {
  pages: Pages;
  services: Services;
  credentials: CredentialManager;
};

export const test = base.extend<CustomFixture>({
  pages: async ({ browser, context, page }, use) => {
    const pages = new Pages(browser, context, page);
    await use(pages);
  },
  services: async ({}, use) => {
    await use(new Services(request));
  },
  credentials: async ({}, use) => {
    await use(new CredentialManager());
  },
});

export { expect } from '@playwright/test';
```

---

## Configuration Patterns

### playwright.config.ts

```typescript
import { defineConfig, devices } from '@playwright/test';

require('dotenv').config();

export default defineConfig({
  testDir: './tests',
  timeout: process.env.LOCAL_DEVELOPMENT === 'true' ? 25000 : 200000,
  fullyParallel: false,
  workers: 7,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  reporter: [
    ['html', { outputFile: './playwright-report/index.html' }],
    ['junit', { outputFile: './playwright-report/playwright-results.xml' }],
  ],
  use: {
    baseURL: process.env.PLAYWRIGHT_TEST_BASE_URL,
    headless: true,
    trace: 'on-first-retry',
    timezoneId: 'UTC',
    locale: 'en-US',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    {
      name: 'setup',
      testMatch: /.*\.setup\.ts/,
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'chromium',
      testMatch: /.*\.spec\.ts/,
      use: {
        ...devices['Desktop Chrome'],
        baseURL: process.env.PLAYWRIGHT_TEST_BASE_URL,
      },
      dependencies: ['setup'],
    },
  ],
});
```

### Storage State Project

```typescript
{
  name: 'chromium-authenticated',
  testMatch: /.*\.spec\.ts/,
  use: {
    ...devices['Desktop Chrome'],
    storageState: './storageState/user.json',
  },
  dependencies: ['setup'],
}
```

---

## Testing Patterns

### Arrange-Act-Assert

```typescript
import { test, expect } from '../fixtures/fixtures';

test.describe('Currency Management', () => {
  test('admin can add exchange rate', async ({ pages: { page } }) => {
    await asUser(User.FinanceSuperAdmin, page);
    const currencyPage = new CurrencyPage(page);

    await currencyPage.gotoCurrencyTab(CurrencyTab.Active);
    await currencyPage.createNewButton.click();
    await currencyPage.selectOption(currencyPage.fromCurrency, 'AUD');
    await currencyPage.selectOption(currencyPage.toCurrency, 'USD');
    await currencyPage.exchangeRate.pressSequentially('1.23');
    await currencyPage.createButton.click();

    const toast = new ToastMixin(page);
    await expect(toast.notificationTitle).toHaveText('FX rate created successfully');
  });
});
```

### Independent Tests

```typescript
test.describe('User Management', () => {
  test.beforeEach(async ({ services, credentials }) => {
    const token = await services.authService.getSuperAdminToken();
    testData.token = token;
  });

  test('creates user', async ({ services }) => {
    const user = await services.userService.createUser(testData.token, userPayload);
    expect(user.id).toBeDefined();
  });

  test.afterEach(async ({ services }) => {
    if (testData.createdUserId) {
      await services.userService.deleteUser(testData.token, testData.createdUserId);
    }
  });
});
```

### Proper Waiting

```typescript
async submitOrder() {
  await this.submitButton.click();
  await this.page.waitForResponse(response =>
    response.url().includes('/api/orders') && response.status() === 200
  );
}

async submitOrder() {
  await this.submitButton.click();
  await this.page.waitForURL('**/order-confirmation');
}
```

---

## Authentication

### Storage State Setup

```typescript
import { test as setup } from '@playwright/test';
import { captureUserStorageState } from '../setup/setup-helper';
import { getSuperAdminCredentials } from '../../credentials/credentials';
import { superAdminStorageStatePath } from '../setup/storageStates';

setup.use({ headless: true });

setup.describe('Capture storageState', () => {
  setup('Get storageState for admin', captureUserStorageState(async () => ({
    credentials: await getSuperAdminCredentials(),
    storageStatePath: superAdminStorageStatePath,
  })));
});
```

### Setup Helper

```typescript
export const captureUserStorageState = (supplier: () => Promise<StorageStateInfo>) =>
  async ({ page, baseURL }) => {
    const { credentials, storageStatePath } = await supplier();
    await page.goto(baseURL);
    await page.locator('#username').fill(credentials.username);
    await page.locator('button[type="submit"]').click();
    await page.locator('#password').fill(credentials.password);
    await page.locator('button[type="submit"]').click();
    await page.waitForURL(`${new URL(page.url()).origin}/**`);
    await page.context().storageState({ path: storageStatePath });
  };
```

### Test Annotations

```typescript
test('admin dashboard', {
  annotations: [{ type: 'storageState', description: './storageState/admin.json' }],
}, async ({ pages }) => {
  await pages.dashboardPage.navigate();
  expect(await pages.dashboardPage.getWelcomeText()).toContain('Admin');
});
```

### Runtime User Switching

```typescript
const stateFor = (user: User) => JSON.parse(fs.readFileSync(statePathFor(user), 'utf-8'));

export const asUser = (user: User, page: Page) =>
  page.context().addCookies(stateFor(user).cookies);
```

---

## API Testing

### Service Fixture for Setup

```typescript
test.beforeAll(async ({ services }) => {
  const token = await services.authService.getSuperAdminToken();
  const partner = await services.partnerService.createPartner(token, partnerPayload);
  testData.partnerId = partner.id;
});

test.beforeEach(async ({ services }) => {
  const token = await services.authService.getSuperAdminToken();
  const invoice = await services.invoiceService.createInvoice(token, invoicePayload);
  testData.invoiceId = invoice.id;
});

test.afterEach(async ({ services }) => {
  await services.invoiceService.deleteInvoice(testData.token, testData.invoiceId);
});
```

---

## CI/CD

### Running in CI

```bash
CI=true npx playwright test
```

### Failure Artifacts

```typescript
use: {
  trace: 'on-first-retry',
  screenshot: 'only-on-failure',
  video: 'retain-on-failure',
},
```

### Test Sharding

```bash
npx playwright test --shard=1/4
npx playwright test --shard=2/4
```

### Package Scripts

```json
{
  "scripts": {
    "test": "npx playwright test",
    "test:headed": "npx playwright test --headed",
    "test:smoke": "npx playwright test -g '@smoke'",
    "report": "npx playwright show-report"
  }
}
```

---

## Common Patterns

### Data-Test-Id Selectors

```typescript
readonly submitButton = page.locator('[data-test-id="submit-order"]');
readonly searchBox = page.locator('[data-test-id="search-box"]');
```

### Dynamic Waiting

```typescript
await this.page.waitForResponse(response =>
  response.url().includes('/api/products') && response.status() === 200
);
await this.page.waitForLoadState('domcontentloaded');
await element.waitFor({ state: 'visible' });
```

### Test Isolation

```typescript
const testData = { token: '', createdIds: [] as string[] };

test.describe('User Management', () => {
  test.beforeEach(async ({ services }) => {
    testData.token = await services.authService.getSuperAdminToken();
  });

  test.afterEach(async ({ services }) => {
    for (const id of testData.createdIds) {
      await services.userService.deleteUser(testData.token, id);
    }
    testData.createdIds.length = 0;
  });
});
```

### Visual Regression

```typescript
await expect(page).toHaveScreenshot('dashboard.png');
```

---

## Checklist

Before completing integration tests, verify:

- [ ] Page objects use `data-test-id` selectors where possible
- [ ] Locators are readonly properties; actions are methods
- [ ] No assertions in page objects
- [ ] No hardcoded timeouts; use `waitForResponse`, `waitForURL`, or `waitFor`
- [ ] Tests import from fixtures, not `@playwright/test` directly
- [ ] Credentials retrieved from secrets manager or env
- [ ] Storage state files are git-ignored
- [ ] Setup tests run before dependent projects
- [ ] Retries configured for CI (e.g., 2)
- [ ] Trace/screenshot/video on failure
- [ ] Tests are independent and clean up after themselves

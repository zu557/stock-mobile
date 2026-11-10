# User guide

## Sign in and navigation

Sign in with an account managed by the Stock-Flow backend. The app restores a saved Better Auth bearer session at startup. Use **Settings → Sign out** to end the session. If the backend rejects a protected API request with 401, the app clears the saved token and returns to the sign-in flow.

The bottom navigation keeps separate stacks for Home, Products, Purchases, Sales, and Settings. Purchases and Sales appear only for roles that can view them. Settings shows the signed-in user's name, email, role, a sign-out action, and category management when allowed.

## Roles and visible actions

The backend is the authority for permissions. The app hides controls for actions the role should not use, but the backend also checks each protected request.

| Role | Mobile access |
| --- | --- |
| `ADMIN` | Products, activation/deactivation, categories including deletion, purchases, sales, and settings |
| `STOREKEEPER` | Product and category management (category deletion is admin-only), and purchase workflows. No Sales tab. |
| `SALES_STAFF` | Active product catalog and sales workflows. No product/category management actions or Purchases tab. |

The backend may apply additional record-level rules, such as restricting which draft purchases a storekeeper can edit or delete.

## Products

- Search product name or code.
- Filter by category and stock status; use the page controls to move through results.
- Pull down on the list to refresh.
- Users with product-management permission can create and edit product code, name, description, unit, reorder level, and category.
- Admins can deactivate an active product or reactivate an inactive product. Each action asks for confirmation when deactivating, shows a spinner while the request is in progress, and refreshes the list after success.
- Inactive products remain visible to administrators and are marked **Inactive**. Sales staff only receive active products in their catalog, and the backend rejects inactive products when creating a sale.
- Current stock and stock status come from the backend. The mobile form does not edit on-hand stock.

Supported units: piece, box, pack, kilogram, liter, and meter. Stock status is `Out of stock`, `Low`, or `In stock`, as calculated by the backend.

## Categories

Open **Settings → Categories** when the role has category-management access. Search by category name, add a category, or edit it. Delete is available to admins; the backend may reject deletion when business constraints prevent it.

## Purchases

Users with purchase access can search by reference number, open purchase details, create a draft, and add products with quantities and unit costs. A draft can be edited or deleted only when allowed by the backend's role and ownership rules. Completing a draft asks for confirmation and lets the backend update inventory and stock movement records.

## Sales

Users with sales access can search by reference number, filter by date range, open sale details, and create a sale with products, quantities, and unit prices. The backend checks active products and stock availability and performs the inventory business logic.

## Current limitations

- Home currently shows placeholder copy rather than inventory metrics.
- Inventory overview, stock adjustments, stock movement history, and reports are not available as mobile screens yet.
- The app does not provide offline browsing or queued offline mutations; screens require a working connection to the backend.
- Some API failures may reflect backend permissions or validation rules. Read the displayed message and, when necessary, ask an administrator to check the backend logs and account role.

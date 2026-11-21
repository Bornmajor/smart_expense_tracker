# The first screen: research and proposal

The question: when someone opens SpendWise IQ, what should they see first? Today
the app opens on the list of expenses, which keeps scrolling. It is good for
finding an expense and weak as a first impression.

## What the research says, and how far to trust it

The searches found design-agency articles, case studies, app store listings and
a few forum posts. They are **patterns, not usability studies**, so treat them
as a guide to what works elsewhere rather than proof. Nothing found measured
what users want on a first screen.

**1. Lead with the money answer, then the detail.** The advice that repeats is to
put the period and the "what is left" number first, and the trend and category
detail below ([budget app dashboard design](https://screensdesign.com/articles/budget-app-dashboard-design/)).
One guide suggests auditing the first screen by asking whether users immediately
understand how much they can spend ([UX Planet, fintech apps](https://uxplanet.org/the-practical-guide-to-designing-great-fintech-apps-ee0340c52dfb)).

**2. Do not give everything equal weight.** Showing accounts, categories,
charts, budgets and tables at once leaves people unsure what matters
([fintech dashboard design examples](https://www.ramotion.com/blog/fintech-dashboard-design-examples/),
[personal finance UX](https://uxplanet.org/using-design-practices-to-build-better-personal-finance-apps-f865663d01d)).
A few strong things beat a wall of numbers.

**3. The usual home screen contents** are the balance or what is left, budget
status, recent transactions and a trend chart. One concept uses a six-month
income-versus-expense line ([Cashly dashboard](https://contra.com/p/BFoNlMs7-cashly-or-finance-dashboard-design)).
Monarch lets people choose what its dashboard shows: budget progress, recent
transactions, upcoming expenses and more ([Monarch on the App Store](https://apps.apple.com/app/id1459319842)).

**4. A daily "safe to spend" number is an established idea.** Quicken Simplifi
shows what is safe to spend for the rest of the month after bills
([The Penny Hoarder review](https://www.thepennyhoarder.com/budgeting/simplifi-app/)),
and a small iOS app divides what is left across the days to the next paycheck
([Safe To Spend](https://apps.apple.com/us/app/-/id6758524287)). SpendWise IQ
already has this card; it just is not on the first screen.

**5. Fast entry matters as much as insight.** Users who abandon expense apps
say logging starts to feel like work ([Product Hunt discussion](https://www.producthunt.com/p/vitmora/why-do-most-people-stop-using-expense-tracking-apps-after-a-few-weeks)),
and the apps praised for speed are the ones with the quickest entry
([Next, App Store](https://apps.apple.com/us/app/next-for-iphone/id596366290)).
Widgets and shortcuts are a recurring request
([Abacus feature request](https://www.github.com/victorbalssa/abacus/issues/261)).
SpendWise IQ already has one-line entry, M-Pesa paste and scanning, and the Add
button must stay visible on the first screen.

**6. Handle the empty first launch.** The advice is to treat it as guided
onboarding, not a blank screen ([UX Planet, fintech apps](https://uxplanet.org/the-practical-guide-to-designing-great-fintech-apps-ee0340c52dfb)).
This is already done for the expense list; the new first screen needs the same.

**7. Trust.** Budget apps ask for sensitive data early, so trust is part of the
design ([Eleken, budget app design](https://eleken.co/blog-posts/budget-app-design)).
For SpendWise IQ the answer is to say, quietly, that everything stays on the
phone.

## What you asked for

A greeting by name, how far you are from your target, a small bar chart of
spending per month for the year, and the Add action. The research agrees with
all four and adds one: recent expenses, so the list is still a glance away.

## Proposal: five things, in this order

A new **Home** tab, first in the bar, which the app opens on. The Expenses list
stays as its own tab, and the Summary keeps the full detail. Home is the glance.

1. **A greeting by name**, such as "Good morning, Maja", with today's date.
   Onboarding gets one optional step asking for a first name. It stays on the
   phone and can be changed in Settings. No name means a plain "Good morning".
2. **The money answer**, one card: this month's spending against the overall
   budget, how much is left, and what is safe to spend each day. With no budget
   set, the card invites the user to set one.
3. **A small bar chart of spending per month for this year**, with the current
   month highlighted. Tapping a bar opens that month on the Summary.
4. **Recent expenses**: the last five, with a "See all" link to the Expenses
   tab. Swipe and tap behave as they do in the list.
5. **Heads-up cards**: the one or two most important alerts, kept short, each
   dismissible, as they are now.

The **Add expense** button stays where it is on every tab, so Add is always one
tap away, as it was asked for.

What stays off the Home screen on purpose: the per-category breakdown, budget
rows for each category, export and the other tools. They live on the Summary,
so Home stays calm.

## Questions to settle before building

- Is a new Home tab right, or should the Summary become the first screen? The
  proposal keeps both because Summary is a detail screen and Home is a glance.
- Should the bar chart show spending only, or also the budget as a line?
  Spending only is simpler and enough to start.
- Is the name step on its own onboarding screen, or a small field on the last
  one? Its own screen is clearer but adds a step; a field on the last screen
  adds none.

## Decided

- A new **Home** tab, first in the bar, which the app opens on. The Expenses list and the Summary stay as their own tabs.
- The year chart shows **spending only**. Tapping a month opens that month's expenses (the Summary has no month to jump to from outside).
- The first name is a **field on the last onboarding screen**, optional, and can be changed in Settings.

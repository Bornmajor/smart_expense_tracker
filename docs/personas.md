# Who the app is for: personas and what they expect

The aim is an expense tracker that serves **most** people well, not everyone.
These personas have different goals so the feature list is tested against more
than one kind of user.

## How much to trust this

The searches found vendor blogs, app listings, student design projects and a few
academic papers, not user studies. The same groups come up again and again, so
the personas are reasonable, but treat them as **hypotheses**. The cheapest way
to check them is to ask five real people which one they are and what they would
change. Sources are listed at the end.

Two findings shaped all of them: people abandon tracking apps when entering
expenses feels like work
([Product Hunt discussion](https://www.producthunt.com/p/vitmora/why-do-most-people-stop-using-expense-tracking-apps-after-a-few-weeks),
[HCI paper on abandonment](https://eprints.lancs.ac.uk/222780/3/Creating_and_Managing_Transactions_and_Budgets-PURE.pdf)),
and some people avoid budget apps because they do not want a nagging reminder
of every small purchase
([commentary](https://robertpuelz.substack.com/p/no-budget-app-fix-now)).

## The personas

### 1. Amina, the first-time budgeter (student or first job, about 21 to 27)
- **Goal:** find out where the money goes, without it becoming a chore.
- **Context:** tracks on paper, or not at all, and is not aware of budgeting
  apps ([budget manager persona study](https://ivypanda.com/essays/budget-manager-apps-market-and-persona/)).
  Little money, so free and light matters. Phone storage and data are tight.
- **Expects:** very fast entry, simple categories, a clear month total, a gentle
  nudge when overspending, no jargon, no account, nothing that feels like homework.
- **We have:** one-line entry, quick scan, categories, Home with the month,
  budgets, works offline with no account, free of ads.
- **Gaps:** savings goals ("I want to save for a laptop"), a widget or shortcut
  to add in two taps, optional end-of-week summary.

### 2. Brian, the salaried city professional (M-Pesa for almost everything)
- **Goal:** stay in control of the month, pay bills on time, save a little.
- **Context:** paid monthly, spends through M-Pesa, paybill and cards, has
  subscriptions and rent. Wants to see the month at a glance.
- **Expects:** M-Pesa capture, recurring bills, what is safe to spend, month
  against last month, bill due reminders, exports.
- **We have:** M-Pesa paste capture, recurring expenses, Safe to spend, budgets,
  heads-up alerts, PDF and CSV export, backup.
- **Gaps:** **income** (to see what is left after pay), bill-due reminders,
  month against last month, sharing a message straight to the app.

### 3. Faith, the freelancer or side-hustler (irregular income)
- **Goal:** know what she actually earned and spent, and be ready for tax.
- **Context:** several clients, uneven months, mixes business and personal
  spending ([what freelancers look for](https://www.getharvest.com/expenses/best-expense-tracker-app-for-freelancers),
  [irregular-income needs](https://www.skillshare.com/projects/633063)).
- **Expects:** income per client, a business or personal flag or tag, receipts
  kept, totals by category for a period, exports she can hand to an accountant.
- **We have:** receipt scan and PDF receipts, categories, CSV and PDF export,
  date and category filters.
- **Gaps:** **income tracking**, a business/personal tag, client or project tag,
  attaching the receipt to the expense, a custom date range in the export.

### 4. Wanjiru and Peter, the couple or family (one household budget)
- **Goal:** one shared picture of the household money, and fewer arguments.
- **Context:** two phones, shared bills, different spending habits
  ([shared budgets](https://www.skillshare.com/projects/633063)).
- **Expects:** both can add expenses, see the same month, split a cost, know who
  owes whom, set a household limit.
- **We have:** budgets, recurring bills, export and backup (a file can be sent
  to the other person).
- **Gaps:** **shared data between two phones** (hard for an offline-first app
  with no account), split expenses and IOUs (on the roadmap), a "who paid" tag.

### 5. Mwangi, the small shop or stall owner
- **Goal:** know if the business is making money.
- **Context:** pays suppliers by M-Pesa and cash, till and paybill, buys stock
  daily, little time to enter things
  ([small business needs](https://www.skillshare.com/projects/633063)).
- **Expects:** quick entry, **sales as well as spending**, profit for the month,
  supplier names, a daily total.
- **We have:** fast entry, M-Pesa capture (till and paybill), vendor memory,
  monthly totals, categories he can rename.
- **Gaps:** **income or sales**, profit (income minus expenses), a separate
  business space. This is the persona the app serves least today.

### 6. David, the debt-payer and saver (cutting costs, building a cushion)
- **Goal:** pay off a loan or Fuliza and save toward something.
- **Context:** tight month, often saves in a chama or mobile savings tool
  ([Chumz and mobile saving tools](https://allafrica.com/stories/202511050044.html)),
  and mobile credit such as Fuliza is easy to overuse
  ([concerns about high-interest mobile loans](https://arxiv.org/html/2507.10970v1)).
- **Expects:** a limit he can see, savings goals with progress, loan payments
  tracked, a warning before he overspends, and no pressure to borrow more.
- **We have:** budgets, Safe to spend, "over budget" warnings, recurring
  payments for repayments, heads-up alerts.
- **Gaps:** **savings goals**, a debt or loan tracker, chama contributions, and
  care in how Fuliza messages are labelled.

### 7. Njeri, the traveller or multi-currency user
- **Goal:** keep everything in one currency while spending in several.
- **Context:** pays in dollars, euros or shillings, wants one honest total.
- **Expects:** convert at the time of entry, see the original amount, current
  rates, no surprises.
- **We have:** the converter with the daily rate, the original amount kept, the
  Kenyan shilling by default.
- **Gaps:** a per-expense currency shown in the list, a trip tag, per-trip totals.

## What the personas share, and where they differ

| Feature | Amina | Brian | Faith | Wanjiru and Peter | Mwangi | David | Njeri |
|---|---|---|---|---|---|---|---|
| Fast entry (type, scan, paste) | needs | needs | needs | needs | needs | needs | needs |
| Month total and categories | needs | needs | needs | needs | needs | needs | needs |
| Budgets and Safe to spend | nice | needs | nice | needs | nice | needs | nice |
| Recurring bills | nice | needs | nice | needs | nice | needs | - |
| Receipts (scan, PDF) | nice | nice | needs | nice | nice | - | nice |
| Backup and export | nice | needs | needs | nice | needs | nice | nice |
| Privacy, offline, no account | needs | nice | nice | nice | nice | nice | nice |
| **Income** | nice | needs | needs | needs | needs | needs | - |
| **Savings goals** | needs | nice | nice | nice | - | needs | - |
| **Bill reminders** | - | needs | nice | needs | nice | needs | - |
| **Tags or accounts** (business and personal, client, trip) | - | - | needs | nice | needs | - | needs |
| **Split, IOUs, shared data** | nice | - | - | needs | - | - | - |

## What this says about priorities

**Already well covered for most personas:** fast entry, categories, the month at
a glance, budgets, Safe to spend, recurring bills, backup and export, privacy.
That is the core, and it is the majority.

**The gaps that come up for several personas at once** (these are the ones worth
building, in this order):
1. **Income.** Five of seven personas need it: pay, client payments or sales.
   With income the app can show what is left, a savings rate, and profit. It is
   the biggest single gap.
2. **Savings goals.** Wanted by the first-time budgeter and the saver, and a
   friendly, positive counterweight to budgets.
3. **Bill reminders.** Useful to four personas, and a natural use of the
   recurring bills already there. A local notification needs no internet, but
   the roadmap's earlier caution about phones that stop background apps applies,
   so it should be gentle and optional.
4. **Tags** (business or personal, client, trip). Serves the freelancer, the
   shop owner and the traveller, and is simple compared with real accounts.

**Not for everyone, deliberately:** shared data between two phones needs an
account and a server, which goes against the offline, private promise. Split
expenses and IOUs (already on the roadmap) cover most of that need without it.
The shop owner's full business bookkeeping is a different product.

## Next step

Show these seven to five real people (the testers), ask which one they are, and
what is missing. The four gaps above are scheduled **last** in the [roadmap](roadmap.md), after the pending work, and the answers decide their order.

## Sources

- [Budget manager apps: market and persona](https://ivypanda.com/essays/budget-manager-apps-market-and-persona/)
- [SplitIt and student budgeting projects (Skillshare)](https://www.skillshare.com/projects/633063)
- [Best expense tracker app for freelancers (Harvest)](https://www.getharvest.com/expenses/best-expense-tracker-app-for-freelancers)
- [Self-employed expense tracking (Expensify)](https://use.expensify.com/self-employed-expense-tracking)
- [Why people stop using expense tracking apps (Product Hunt)](https://www.producthunt.com/p/vitmora/why-do-most-people-stop-using-expense-tracking-apps-after-a-few-weeks)
- [Creating and managing transactions and budgets (Lancaster University)](https://eprints.lancs.ac.uk/222780/3/Creating_and_Managing_Transactions_and_Budgets-PURE.pdf)
- [People are tracking spending more closely (NerdWallet)](https://www.nerdwallet.com/finance/studies/tracking-spending-more-closely)
- [How mobile tools are building a saving culture in Kenya](https://allafrica.com/stories/202511050044.html)
- [Jasho app for informal and gig workers (Business Daily)](https://www.businessdailyafrica.com/bd/corporate/enterprise/young-womens-jasho-app-seeks-to-transform-informal-work-5466940)
- [Exploitation in mobile-based financial services](https://arxiv.org/html/2507.10970v1)

# Review Plan Upgrade Design

## Architecture

The feature is implemented completely on the Flutter offline client.

Main modules:

- `MistakeRepository`
  - Generates notebook-scoped daily plans
  - Tracks reviewed items for the plan scope
  - Calculates report data and review metadata
  - Applies spaced-repetition-like prioritization
- `MobileHome`
  - Stores current study notebook context
  - Uses notebook-scoped dashboard progress
  - Starts review sessions from the home dashboard
- `ReviewPlanReportPage`
  - Displays the report-style plan summary
  - Visualizes today's plan with bar-chart-like blocks
  - Starts the remaining plan session
- `ReviewPlanSessionPage`
  - Runs through today's remaining planned mistakes sequentially
  - Records results and advances through the plan
  - Shows completion state and links to check-in
- `MistakeReviewPage`
  - Keeps single-mistake review flow for manual entry points
  - Displays metadata such as created time and first reviewed time

## Data Strategy

No schema migration is required.

Existing inputs reused:

- `mistakes`
  - `masteryStatus`
  - `reviewCount`
  - `createdAt`
  - `lastReviewedAt`
- `review_events`
  - Used to calculate failure pressure, first review time, and consecutive mastery streak

SharedPreferences keys are updated to be notebook-scoped for:

- plan date
- plan ids
- reviewed ids for today

Global streak keys remain shared.

## Review Scheduling Logic

Each mistake gets a plan candidate score based on:

- never reviewed boost
- reviewed yesterday but still not mastered boost
- days since last review
- recent failure count
- total failure count
- mastery status
- consecutive mastered streak
- delayed interval for stable mastered items

Intervals for repeatedly mastered items expand approximately like:

- 1 correct streak -> 1 day
- 2 correct streak -> 2 days
- 3 correct streak -> 4 days
- 4 correct streak -> 7 days
- 5 correct streak -> 15 days
- 6+ correct streak -> 30 days

This does not claim to be a perfect Ebbinghaus implementation, but it follows the same product intent:

- fragile memory surfaces quickly
- stable memory cools down
- repeated failures remain near the front of the queue

## UX Design

### Home Dashboard

- Keep the upgraded editorial hero card
- Show `今日完成 / 今日计划 / 连续打卡`
- “开始复习” starts today's remaining plan for the current notebook

### Notebook Detail

- Remove random-review emphasis
- Add “复习计划” report entry
- Add “开始计划” action for direct execution

### Review Plan Report

- Top summary card
- Progress bar / completion ratio
- Column bars for plan metrics
- Risk cards for:
  - yesterday failed
  - overdue and stale
  - hard mistakes
  - cooling mastered mistakes
- Action button to start today's remaining plan

### Check-in Page

- Make it more ceremonial
- Show streak, today's status, and progress

### Single Mistake Review

- Keep flip/reveal flow
- Add metadata block:
  - created time
  - first reviewed time
  - current mastery
  - total reviews / recent pressure

## Testing Strategy

- Extend repository tests to ensure plan generation and review recording still work
- Keep widget smoke tests passing for dashboard
- Run `flutter analyze`
- Run `flutter test`

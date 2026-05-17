# Implementation Plan

- [x] 1. Define review-plan product behavior and report-style UX
  - Capture dashboard, report page, session page, and check-in behavior
  - Define notebook-scoped assumptions and acceptance boundaries
  - _Requirement: 1, 2, 3, 7, 8, 9_

- [x] 2. Upgrade review planning logic in `MistakeRepository`
  - Make plan cache keys notebook-scoped
  - Add history-based scoring and delayed mastered intervals
  - Add review metadata and report aggregation methods
  - _Requirement: 4, 5, 6, 7_

- [x] 3. Add plan report and plan session pages
  - Build report-style page with visual metrics
  - Build sequential session page for remaining planned mistakes
  - _Requirement: 2, 3, 8_

- [x] 4. Wire the dashboard and notebook flows into the new plan UX
  - Start review from the home dashboard using the current notebook scope
  - Replace random-review emphasis in notebook detail with plan actions
  - _Requirement: 1, 2, 3_

- [x] 5. Upgrade check-in and single-review presentation
  - Refresh check-in screen visual design
  - Add first-review and mastery metadata to the single-mistake review screen
  - _Requirement: 8, 9_

- [x] 6. Validate the implementation
  - Update or add tests where required
  - Run `flutter analyze` and `flutter test`
  - _Requirement: 1, 2, 3, 4, 5, 6, 7, 8, 9_

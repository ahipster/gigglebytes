# Implementation Plan - Survivorship Logic Enhancements

This plan covers the visual and functional enhancement of the Survivorship Strategy module.

## Proposed Changes

### [Survivorship] Advanced Strategy UI
- **File**: `survivorship-rules.html`
- **Change**: Replace the static list with a more dynamic "Strategy Matrix".
    - **Global Precedence**: Add more sources (e.g., Bloomberg, LEI.direct) and simulated "Most Recent Wins" toggle.
    - **Field-Level Rules**: Add a grid displaying common fields (Legal Name, Address, Registration) with their specific survivorship method (e.g., Source Rank vs. Longest Value).
    - **Methods**: Introduce new strategies:
        - **Trust Score**: Based on source reliability.
        - **Recency**: Last Updated Date (LUD).
        - **Aggregation**: Majority wins (if 2/3 agree).

### [Survivorship] Golden Record Simulation (The "WOW" Feature)
- **File**: `survivorship-rules.html`
- **Change**: Add a "Simulation & Preview" bottom panel.
    - **Input**: A mock "Conflict Record" showing data from 3 different sources (Source A, B, C) for the same field.
    - **Execution**: A "Solve Conflict" button that shows how the current strategy picks the winner.
    - **Output**: The final predicted "Golden Record" value with a rationale badge (e.g., "Winner: GLEIF via Global Rank").

## Verification Plan

### Manual Verification
- **Versioning**: Switch between v1.2 and v1.3 to ensure the unreleased banner/logic persists correctly.
- **Simulation**: Click the "Solve Conflict" button to see the animated calculation of the Golden Record.
- **Aesthetics**: Ensure the matrix and simulation panel feel high-density and professional.

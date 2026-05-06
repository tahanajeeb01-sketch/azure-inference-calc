I want you to build an app for me. It helps 1st graders understand and solve comparison problems.
A comparison problem is something like this: “Jack has 5 apples. Jill has 10 more apples. How many apples does Jill have?”. So you need to do this: enter a word problem. Put an answer button infront of the problem. When child/user clicks the answer button, draw a big recangle, then right below draw a small rectangle, and to side of the small rectangle draw a small circle. In the big rectangle, put the bigger number, in the small rectangle, put the smaller number, and in the circle put the comparison number. For eg, in the example above, Jill’s number goes into smaller rectangle (because Jill has more), a “?” goes into the big rectangle because we don’t know that answer yet, and then 5 goes into the circle. Now when user clicks the ?, then show the actual answer in the form of equation, in the example above it will be 10+5=15.

So sequence of steps:
-	Display word problem
-	User clicks answer
-	Show big rectangle. Wait for 12 seconds and then show smaller rectangle. Wait another 12 seconds, show the circle.
-	Highlight numbers in the question and populate them in their respective figures. ? goes into figure where answer is not known yet. Small or big number goes into small or big rectangle respectively. Comparison number goes into circle
-	When user click ?, then show answer in the form of equation
I want you to build an app for me. It helps 1st graders understand and solve comparison problems.
A comparison problem is something like this: “Jack has 5 apples. Jill has 10 more apples. How many apples does Jill have?”. So you need to do this: enter a word problem. Put an answer button infront of the problem. When child/user clicks the answer button, draw a big recangle, then right below draw a small rectangle, and to side of the small rectangle draw a small circle. In the big rectangle, put the bigger number, in the small rectangle, put the smaller number, and in the circle put the comparison number. For eg, in the example above, Jill’s number goes into smaller rectangle (because Jill has more), a “?” goes into the big rectangle because we don’t know that answer yet, and then 5 goes into the circle. Now when user clicks the ?, then show the actual answer in the form of equation, in the example above it will be 10+5=15.

So sequence of steps:
-	Display word problem
-	User clicks answer
-	Show big rectangle. Wait for 12 seconds and then show smaller rectangle. Wait another 12 seconds, show the circle.
-	Highlight numbers in the question and populate them in their respective figures. ? goes into figure where answer is not known yet. Small or big number goes into small or big rectangle respectively. Comparison number goes into circle
-	When user click ?, then show answer in the form of equation
# Azure Inference Calculator Architecture

## Overview

This application is a **static, client-side web app** built entirely in a single HTML file: `index.html`.
It does not use any server-side runtime, backend API, or database.
All logic and data are embedded in the page as JavaScript arrays and functions.

## High-Level Architecture

1. **User Interface**
   - `index.html` contains the UI, styling, and app logic.
   - The form accepts:
     - City input with autocomplete
     - Workload type
     - Target latency

2. **Data Sources**
   - City list: supported cities and coordinates
   - Edge POP list: ExpressRoute peering locations
   - AEZ list: live Azure Extended Zone metros
   - Standard Azure regions: fallback compute locations
   - GPU recommendation map: workload to GPU compute size

3. **Calculation Engine**
   - Converts user city selection into coordinates
   - Finds the nearest Edge POP using distance formulas
   - Compares the closest AEZ and standard Azure region
   - Uses a latency model for each path
   - Recommends:
     - AEZ only if a live AEZ exists and latency budget is met
     - Standard region otherwise

4. **Result Rendering**
   - The app updates the DOM with:
     - Recommended deployment type
     - Recommended Azure region or AEZ city
     - GPU recommendation
     - Latency breakdown
     - Human-readable explanation

## Data Storage

There is no database in this app.

- The city catalog, Edge POP locations, AEZ locations, and region metadata are hardcoded in `index.html`.
- User entries are not saved anywhere.
- The app does not persist history, logs, or settings.
- Every browser refresh clears the current selection and output.

## Where the Data Lives

All application data is stored in JavaScript variables inside `index.html`.
For example:

- `cities` contains city names, countries, latitudes, and longitudes
- `edgePOPs` contains Edge POP names and coordinates
- `aezLocations` contains live AEZ locations
- `standardRegions` contains Azure region coordinates
- `gpuRecommendations` maps workloads to GPU guidance

## Execution Flow

1. User types a city name.
2. The autocomplete logic finds matching entries.
3. User selects a matched city.
4. User selects a workload and enters a latency target.
5. User clicks `Calculate Recommendation`.
6. Calculation functions run in the browser:
   - `findClosestEdgePOP()` determines the nearest Edge POP.
   - `findClosestAEZFromEdge()` finds the nearest configured AEZ.
   - `findClosestRegionFromEdge()` finds the nearest Azure region.
   - `calculateLatency()` converts distance into estimated latency.
7. The app chooses AEZ only if it is available and within budget.
8. The result is rendered on screen.

## Key Files

- `index.html` — entire app: UI, CSS, data, logic, and rendering
- `azure.yaml` — Azure Developer CLI configuration for deployment
- `main.bicep` — Azure resource definition for the app (static site)
- `.azure/deployment-plan.md` — deployment plan and notes

## Deployment

The app is designed for static hosting:

- It can be deployed as an Azure Static Web App
- `azure.yaml` is used by Azure Developer CLI (`azd`)
- `main.bicep` defines the infrastructure

## Important Notes

- This is a **single-page, stateless application**.
- There is **no backend service** and **no DB**.
- If you need to save user entries, you will need to add:
  - a backend API
  - a database or persistent storage
  - authentication/session state

## Recommended Next Step

If you want persistence later, the next architectural addition would be:

- a small REST API or serverless function
- a database like Azure Cosmos DB, Azure SQL, or Azure Table Storage
- client-side form submission to the API

For now, the app is intentionally simple and entirely front-end.

# Azure Inference Calculator - Technical Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [File Structure](#file-structure)
3. [index.html - Complete Code Walkthrough](#indexhtml---complete-code-walkthrough)
4. [azure.yaml - Azure Deployment Configuration](#azureyaml---azure-deployment-configuration)
5. [main.bicep - Infrastructure as Code](#mainbicep---infrastructure-as-code)
6. [Architecture & Logic](#architecture--logic)

---

## Project Overview

**Purpose**: Help users find the optimal Azure region for AI inference workloads based on:
- Their geographic location (city)
- Target latency requirements
- Workload type (LLM, embedding, image generation, etc.)

**Key Features**:
- City input with fuzzy matching (55+ cities worldwide)
- Real-time latency calculation using speed-of-light physics
- AEZ vs Standard Region recommendation engine
- GPU selection with detailed rationale

---

## File Structure

```
Inference Calc/
├── index.html          # Main web app (HTML + CSS + JavaScript)
├── azure.yaml          # Azure Developer CLI configuration
├── main.bicep         # Infrastructure as Code (pre-existing)
└── .azure/
    └── deployment-plan.md
```

---

## index.html - Complete Code Walkthrough

### Section 1: HTML Structure (Lines 1-50)

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Azure Inference Calculator</title>
```
- **DOCTYPE**: Declares HTML5 standard
- **charset=UTF-8**: Supports international characters
- **viewport**: Enables responsive design on mobile devices

### Section 2: CSS Styles (Lines 51-280)

The styles use a GitHub-inspired dark theme:

```css
body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background: linear-gradient(135deg, #0d1117 0%, #161b22 100%);
    min-height: 100vh;
    padding: 40px 20px;
}
```
- **Background**: Dark gradient (#0d1117 → #161b22)
- **Font**: Segoe UI (Windows system font)
- **min-height: 100vh**: Full viewport height

#### Key CSS Classes:

| Class | Purpose |
|-------|---------|
| `.card` | Main content container with border |
| `.autocomplete-wrapper` | Container for city input + dropdown |
| `.autocomplete-dropdown` | Hidden by default, shown on input |
| `.btn-calculate` | Gradient button (green → blue) |
| `.badge-aez` / `.badge-region` | Color-coded deployment type badges |
| `.result-grid` | 4-column responsive grid |
| `.latency-breakdown` | 3-column hop-by-hop latency display |
| `.gpu-rationale` | Highlighted GPU explanation box |

### Section 3: HTML Form Elements (Lines 281-340)

```html
<div class="form-group">
    <label for="city">📍 Your Location (City)</label>
    <div class="autocomplete-wrapper">
        <input type="text" id="city" placeholder="e.g., Los Angeles, London, Tokyo..." autocomplete="off">
        <div class="autocomplete-dropdown" id="cityDropdown"></div>
    </div>
</div>
```

- **autocomplete="off"**: Disable browser autocomplete
- **id="cityDropdown"**: JavaScript populates this with matches

```html
<div class="form-group">
    <label for="workload">🎯 Workload Type</label>
    <select id="workload">
        <option value="">Select your workload...</option>
        <option value="llm">Large Language Model (LLM) - Chat/Completion</option>
        <option value="embedding">Text Embedding - Vector Search</option>
        <option value="image">Image Generation - Diffusion Models</option>
        <option value="speech">Speech Processing - STT/TTS</option>
        <option value="realtime">Real-time Inference - Low Latency</option>
    </select>
</div>
```

- **5 workload types** map to GPU recommendations
- Each option has a descriptive label

```html
<div class="form-group">
    <label for="latency">⏱️ Target Latency (ms)</label>
    <input type="number" id="latency" placeholder="e.g., 15" min="1" max="1000" value="20">
</div>
```

- **Default value: 20ms** (typical for interactive apps)
- **min="1" max="1000"**: Reasonable bounds

```html
<button class="btn-calculate" id="calculateBtn" onclick="calculate()" disabled>Calculate Recommendation</button>
```

- **disabled**: Button only enables after city is selected

### Section 4: JavaScript - Data Structures (Lines 350-500)

#### 4.1 City Database

```javascript
const cities = [
    { name: "Los Angeles", country: "USA", lat: 34.0522, lng: -118.2437 },
    { name: "New York", country: "USA", lat: 40.7128, lng: -74.0060 },
    // ... 55+ cities
];
```

**Purpose**: Master list of supported cities with coordinates
- **lat/lng**: Decimal degrees (WGS84)
- **country**: Display purposes

#### 4.2 Edge POPs (ExpressRoute Peering Locations)

```javascript
const edgePOPs = [
    { name: "Los Angeles", lat: 34.0522, lng: -118.2437, region: "West US" },
    { name: "New York", lat: 40.7128, lng: -74.0060, region: "East US" },
    // ... 50+ Edge POPs
];
```

**Purpose**: Where customers peer with Microsoft via ExpressRoute
- **region**: Azure region this POP maps to
- Used to calculate: `User → Edge POP` distance

#### 4.3 AEZ Locations (Azure Extended Zones)

```javascript
const aezLocations = [
    { city: "Los Angeles", region: "West US", lat: 34.0522, lng: -118.2437 },
    { city: "New York", region: "East US 2", lat: 40.7128, lng: -74.0060 },
    // ... ~30 AEZ locations
];
```

**Purpose**: Subset of Edge POPs with direct GPU access
- Based on [ExpressRoute Metro](https://learn.microsoft.com/azure/expressroute/metro)
- Used to calculate: `Edge POP → AEZ` latency

#### 4.4 Standard Azure Regions

```javascript
const standardRegions = [
    { city: "East US", region: "East US", lat: 37.5, lng: -79 },
    { city: "West US 3", region: "West US 3", lat: 33.4, lng: -112 },
    // ... 24 regions
];
```

**Purpose**: Fallback when AEZ doesn't meet latency
- Used to calculate: `Edge POP → Region` latency

#### 4.5 GPU Recommendations

```javascript
const gpuRecommendations = {
    llm: { 
        name: 'NC A100 v4', 
        vcpus: '24-48', 
        memory: '880 GB/s',
        rationale: 'The NC A100 v4 series is optimized for large language models...'
    },
    // ... 5 workload types
};
```

**Purpose**: Map workload type to GPU VM size with rationale

| Workload | GPU | vCPUs | Rationale |
|----------|-----|-------|-----------|
| LLM | NC A100 v4 | 24-48 | High token throughput, FP16/FP32 |
| Embedding | NCads A100 v4 | 12-24 | Cost-effective, local SSD |
| Image | ND A100 v4 | 32-64 | Distributed inference, high memory |
| Speech | NC A100 v4 | 16-32 | Low latency, balanced compute |
| Realtime | NC A100 v4 | 16-32 | Consistent latency, direct GPU |

### Section 5: JavaScript - Utility Functions (Lines 500-600)

#### 5.1 Haversine Distance Formula

```javascript
function haversineDistance(lat1, lng1, lat2, lng2) {
    const R = 6371; // Earth's radius in km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLng = (lng2 - lng1) * Math.PI / 180;
    const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
              Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
              Math.sin(dLng/2) * Math.sin(dLng/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
}
```

**Purpose**: Calculate great-circle distance between two points on Earth

**How it works**:
1. Convert lat/lng to radians
2. Apply spherical law of cosines
3. Multiply by Earth's radius (6,371 km)

**Formula**: `d = R × arccos(sin φ₁ × sin φ₂ + cos φ₁ × cos φ₂ × cos Δλ)`

#### 5.2 Latency Calculation

```javascript
const SPEED_OF_LIGHT = 200000; // km/s

function calculateLatency(distanceKm) {
    const propagationDelay = (distanceKm / SPEED_OF_LIGHT) * 1000; // ms
    const networkOverhead = 1.5; // ms for routing, switching
    return Math.round(propagationDelay + networkOverhead);
}
```

**Purpose**: Convert distance to estimated latency

**Assumptions**:
- **200,000 km/s**: Speed of light in fiber (typically ~150-200k km/s)
- **1.5ms**: Fixed overhead for routing, switching, equipment delay

**Example**:
- Distance: 1,000 km
- Propagation: (1000 ÷ 200000) × 1000 = 5ms
- Total: 5 + 1.5 = **6.5ms**

#### 5.3 Fuzzy City Matching

```javascript
function fuzzyMatch(input, cities) {
    const lowerInput = input.toLowerCase();
    return cities
        .map(city => {
            const lowerName = city.name.toLowerCase();
            let score = 0;
            
            // Exact match = 100
            if (lowerName === lowerInput) score = 100;
            // Starts with = 80
            else if (lowerName.startsWith(lowerInput)) score = 80;
            // Contains = 60
            else if (lowerName.includes(lowerInput)) score = 60;
            // Prefix match = 40
            else if (lowerInput.length > 2 && 
                     lowerName.substring(0, lowerInput.length) === 
                     lowerInput.substring(0, 2)) score = 40;
            
            return { ...city, score };
        })
        .filter(c => c.score > 0)
        .sort((a, b) => b.score - a.score)
        .slice(0, 8);
}
```

**Purpose**: Find matching cities as user types

**Scoring Priority**:
1. Exact match: 100 points
2. Starts with input: 80 points
3. Contains input: 60 points
4. First 2 chars match: 40 points

**Returns**: Top 8 matches, sorted by score

#### 5.4 Finding Closest Infrastructure

```javascript
function findClosestEdgePOP(userLat, userLng) {
    let closest = null;
    let minDist = Infinity;
    
    for (const pop of edgePOPs) {
        const dist = haversineDistance(userLat, userLng, pop.lat, pop.lng);
        if (dist < minDist) {
            minDist = dist;
            closest = pop;
        }
    }
    
    return { pop: closest, distance: minDist };
}
```

**Purpose**: Find nearest Edge POP to user location

**Returns**: Object with:
- `pop`: The closest Edge POP object
- `distance`: Distance in km

```javascript
function findClosestAEZFromEdge(edgePop) {
    let closest = null;
    let minDist = Infinity;
    
    for (const aez of aezLocations) {
        const dist = haversineDistance(edgePop.lat, edgePop.lng, aez.lat, aez.lng);
        if (dist < minDist) {
            minDist = dist;
            closest = aez;
        }
    }
    
    return { aez: closest, distance: minDist };
}
```

**Purpose**: Find nearest AEZ from the Edge POP (not from user)

**Key Insight**: 
- `findClosestEdgePOP`: User → Edge POP
- `findClosestAEZFromEdge`: Edge POP → AEZ
- This models the actual network path: `User → Edge POP → Azure`

### Section 6: JavaScript - UI Event Handlers (Lines 600-680)

#### 6.1 City Input Handler

```javascript
let selectedCity = null;

const cityInput = document.getElementById('city');
const dropdown = document.getElementById('cityDropdown');

cityInput.addEventListener('input', function() {
    const input = this.value.trim();
    if (input.length < 2) {
        dropdown.classList.remove('show');
        return;
    }

    const matches = fuzzyMatch(input, cities);
    
    if (matches.length === 0) {
        dropdown.classList.remove('show');
        return;
    }

    dropdown.innerHTML = matches.map(city => `
        <div class="autocomplete-item" 
             data-name="${city.name}" 
             data-country="${city.country}" 
             data-lat="${city.lat}" 
             data-lng="${city.lng}">
            <span class="autocomplete-city">${city.name}</span>
            <span class="autocomplete-country">${city.country}</span>
        </div>
    `).join('');

    dropdown.classList.add('show');
});
```

**Behavior**:
1. On input, wait for ≥2 characters
2. Run fuzzyMatch against city database
3. Build HTML for dropdown items
4. Show dropdown

**Data Attributes**: Each item stores:
- `data-name`: City name
- `data-country`: Country
- `data-lat`: Latitude
- `data-lng`: Longitude

#### 6.2 Dropdown Click Handler

```javascript
dropdown.addEventListener('click', function(e) {
    const item = e.target.closest('.autocomplete-item');
    if (item) {
        selectedCity = {
            name: item.dataset.name,
            country: item.dataset.country,
            lat: parseFloat(item.dataset.lat),
            lng: parseFloat(item.dataset.lng)
        };
        cityInput.value = `${selectedCity.name}, ${selectedCity.country}`;
        dropdown.classList.remove('show');
        document.getElementById('calculateBtn').disabled = false;
    }
});
```

**Behavior**:
1. Detect click on autocomplete item
2. Parse data attributes into `selectedCity` object
3. Update input field with full name
4. Hide dropdown
5. Enable calculate button

#### 6.3 Click Outside to Close

```javascript
document.addEventListener('click', function(e) {
    if (!e.target.closest('.autocomplete-wrapper')) {
        dropdown.classList.remove('show');
    }
});
```

**Purpose**: Close dropdown when clicking elsewhere

### Section 7: Main Calculation Function (Lines 680-800)

```javascript
function calculate() {
    const workload = document.getElementById('workload').value;
    const targetLatency = parseInt(document.getElementById('latency').value);

    if (!selectedCity || !workload || !targetLatency) {
        alert('Please fill in all fields');
        return;
    }

    // Step 1: Find closest Edge POP from user location
    const edgeInfo = findClosestEdgePOP(selectedCity.lat, selectedCity.lng);
    
    // Step 2: From Edge POP, find closest AEZ and standard region
    const aezFromEdge = findClosestAEZFromEdge(edgeInfo.pop);
    const regionFromEdge = findClosestRegionFromEdge(edgeInfo.pop);

    // Step 3: Calculate latencies
    const edgeToAEZ = calculateLatency(aezFromEdge.distance);
    const edgeToRegion = calculateLatency(regionFromEdge.distance);
```

**Step-by-Step Logic**:

| Step | Function | Input | Output |
|------|----------|-------|--------|
| 1 | `findClosestEdgePOP` | User lat/lng | Closest Edge POP + distance |
| 2 | `findClosestAEZFromEdge` | Edge POP lat/lng | Closest AEZ + distance |
| 3 | `findClosestRegionFromEdge` | Edge POP lat/lng | Closest Region + distance |
| 4 | `calculateLatency` | Distances | Latencies in ms |

#### 7.1 Decision Logic

```javascript
if (edgeToAEZ < targetLatency) {
    // AEZ meets the latency requirement
    recommended = aezFromEdge.aez;
    deploymentType = 'AEZ';
    explanation = `Your target latency is <strong>${targetLatency}ms</strong>. ` +
        `From your nearest Edge POP in <strong>${edgeInfo.pop.name}</strong>, ` +
        `the closest AEZ is <strong>${aezFromEdge.aez.city}</strong> at <strong>${edgeToAEZ}ms</strong>. ` +
        `This meets your latency requirement, so we recommend an <strong>Azure Extended Zone (AEZ)</strong>. ` +
        `AEZs provide direct GPU access with minimal network hops, ideal for latency-sensitive AI inference.`;
} 
else if (edgeToRegion < targetLatency) {
    // Standard region meets the latency requirement
    recommended = regionFromEdge.region;
    deploymentType = 'Region';
    explanation = `...`;
} 
else {
    // Neither meets the requirement
    recommended = aezFromEdge.aez;
    deploymentType = 'AEZ';
    explanation = `...`;
}
```

**Decision Matrix**:

| Condition | Result |
|-----------|--------|
| AEZ latency < target | Recommend AEZ |
| AEZ ≥ target, Region < target | Recommend Region |
| Both ≥ target | Recommend closest AEZ (with warning) |

#### 7.2 UI Update

```javascript
// Update UI
document.getElementById('userLocation').textContent = 
    `${selectedCity.name}, ${selectedCity.country}`;
document.getElementById('estLatency').textContent = 
    `${Math.min(edgeToAEZ, edgeToRegion)}ms`;
document.getElementById('region').textContent = recommended.region;
document.getElementById('gpu').textContent = gpu.name;

// Badge
const badge = document.getElementById('deploymentType');
badge.textContent = deploymentType;
badge.className = 'badge ' + (deploymentType === 'AEZ' ? 'badge-aez' : 'badge-region');
```

#### 7.3 Latency Breakdown Display

```javascript
document.getElementById('latencyBreakdown').innerHTML = `
    <div class="latency-item">
        <div class="latency-item-label">${selectedCity.name} → Edge POP (${edgeInfo.pop.name})</div>
        <div class="latency-item-value">${Math.round(edgeInfo.distance)}km</div>
    </div>
    <div class="latency-item">
        <div class="latency-item-label">Edge POP → AEZ (${aezFromEdge.aez.city})</div>
        <div class="latency-item-value">${edgeToAEZ}ms</div>
    </div>
    <div class="latency-item">
        <div class="latency-item-label">Edge POP → Region (${regionFromEdge.region.region})</div>
        <div class="latency-item-value">${edgeToRegion}ms</div>
    </div>
`;
```

**Display Format**:
```
┌─────────────────────────────┬────────────┐
│ LA User → Edge POP (LA)     │ ~0 km      │
├─────────────────────────────┼────────────┤
│ Edge POP → AEZ (West US)    │ ~2 ms      │
├─────────────────────────────┼────────────┤
│ Edge POP → Region (West US 3) │ ~4.5 ms   │
└─────────────────────────────┴────────────┘
```

#### 7.4 GPU Rationale Display

```javascript
document.getElementById('gpuRationale').textContent = gpu.rationale;
```

---

## azure.yaml - Azure Deployment Configuration

```yaml
# Azure Developer CLI Configuration
# https://learn.microsoft.com/azure/developer/azure-developer-cli/azd-reference

name: inference-calc
services:
  web:
    project: ./index.html
    host: static
    hooks:
      post-deploy:
        run: echo "Static website deployed!"
        shell: sh
```

**Purpose**: Configure Azure Static Web Apps deployment

| Field | Value | Description |
|-------|-------|-------------|
| `name` | inference-calc | App name |
| `project` | ./index.html | Static files location |
| `host` | static | Static Web Apps host |
| `hooks.post-deploy` | echo | Post-deployment message |

---

## main.bicep - Infrastructure as Code

*(Pre-existing file - not modified)*

---

## Architecture & Logic Summary

> For a separate high-level architecture overview, see [`ARCHITECTURE.md`](ARCHITECTURE.md).

### Network Path Model
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  User City  │────▶│  Edge POP   │────▶│   Azure     │
│ (Your Input)│     │ (ExpressRoute)│    │ (AEZ/Region)│
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │                    │
   Distance to        Distance to         Latency
   closest Edge       closest AEZ/        calculation
   POP                Region
```

### Latency Calculation Flow
1. **User → Edge POP**: Distance in km (not latency, assumes user has ER connection)
2. **Edge POP → AEZ**: `(distance ÷ 200,000) × 1000 + 1.5ms`
3. **Edge POP → Region**: Same formula

### Why This Model?
- Customers connect to Microsoft via ExpressRoute at nearest Edge POP
- From Edge POP, traffic routes to Azure region/AEZ
- Speed of light in fiber ≈ 200,000 km/s
- Adding 1.5ms accounts for routing/switching overhead

### Example Calculations

**Example 1: Los Angeles, 20ms target**
- Closest Edge POP: Los Angeles (0 km)
- Edge → AEZ (West US): ~2 ms ✅
- Edge → Region (West US 3): ~4 ms ✅
- **Recommendation**: AEZ (2ms < 20ms)

**Example 2: Denver, 15ms target**
- Closest Edge POP: Denver (~0 km)
- Edge → AEZ (Dallas): ~7 ms ✅
- Edge → Region (Central US): ~5.5 ms ✅
- **Recommendation**: Region (5.5ms < 15ms, closer to target)

---

## Running the App

### Local Testing
1. Open `index.html` in any browser
2. Type a city name (e.g., "Los Ange")
3. Select from dropdown
4. Choose workload type
5. Set target latency
6. Click "Calculate Recommendation"

### Deploy to Azure
```powershell
azd up
```

This creates an Azure Static Web App (Free tier).

---

## Future Enhancements

1. **Real latency data**: Replace calculations with actual measurements from Azure Network Watcher
2. **More cities**: Expand city database
3. **Cost estimation**: Add pricing data for GPU VMs
4. **Multi-region**: Support for geo-distributed deployments
5. **Edge computing**: Add Azure Edge Zone recommendations
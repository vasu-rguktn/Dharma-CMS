# Offline Petition Assignment Feature - Implementation Plan

## Overview
Implement a comprehensive offline petition assignment system where:
- **High-level officers (DGP to SP)**: Can see **"Sent"** and **"Assigned"** tabs
  - **Sent**: Petitions they have assigned to others
  - **Assigned**: Petitions assigned to them by higher officers
- **Low-level officers (below SP)**: Can see only **"Assigned"** tab
  - **Assigned**: Petitions assigned to them by higher officers

## Police Hierarchy Structure
Based on `ap_police_hierarchy_complete.json`:

### High-Level Officers (DGP to SP):
- DGP (Director General of Police)
- ADGP (Additional Director General of Police)
- IGP (Inspector General of Police)
- DIG (Deputy Inspector General of Police)
- SP (Superintendent of Police)

### Low-Level Officers (Below SP):
- ASP (Additional Superintendent of Police)
- DSP (Deputy Superintendent of Police)
- CI (Circle Inspector)
- SI (Sub-Inspector)
- ASI (Assistant Sub-Inspector)
- HC (Head Constable)
- PC (Police Constable)

## Implementation Components

### 1. Provider Enhancement (`petition_provider.dart`)
Add methods to:
- Fetch petitions sent by an officer (assignedBy = officerId)
- Fetch petitions assigned to an officer (assignedTo = officerId)
- Fetch petitions assigned to a station/district/range

### 2. New Screen (`offline_petitions_screen.dart`)
Create a tabbed interface with:
- Horizontal swipeable tabs
- "Sent" tab (for high-level officers only)
- "Assigned" tab (for all officers)
- Dynamic tab bar based on officer rank

### 3. Utility Function (`rank_utils.dart`)
Helper to determine if an officer is high-level or low-level

### 4. Integration with Police Dashboard
Add navigation to the offline petitions screen from the dashboard

## Data Structure
The `Petition` model already contains the necessary fields:
- `assignedBy` - UID of assigning officer
- `assignedByName` - Name of assigning officer
- `assignedTo` - Officer UID assigned to
- `assignedToName` - Officer name
- `assignedToRank` - Officer rank
- `assignedToRange` - Range assigned to
- `assignedToDistrict` - District assigned to
- `assignedToStation` - Station assigned to
- `assignedAt` - Assignment timestamp
- `assignmentStatus` - 'pending', 'accepted', 'rejected'
- `assignmentNotes` - Optional notes

## User Stories

### US1: High-Level Officer Views Sent Petitions
**As a** DGP/ADGP/IGP/DIG/SP officer  
**I want to** view petitions I have assigned to others  
**So that** I can track the status of delegated work

### US2: High-Level Officer Views Assigned Petitions
**As a** DGP/ADGP/IGP/DIG/SP officer  
**I want to** view petitions assigned to me by higher authorities  
**So that** I can work on cases delegated to me

### US3: Low-Level Officer Views Assigned Petitions
**As a** ASP/DSP/CI/SI/ASI/HC/PC officer  
**I want to** view petitions assigned to me  
**So that** I can work on delegated cases

### US4: Officer Can Assign Petitions
**As a** police officer  
**I want to** assign petitions to other officers or units  
**So that** work can be distributed efficiently

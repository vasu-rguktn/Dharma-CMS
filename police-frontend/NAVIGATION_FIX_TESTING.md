# Navigation Fix - Testing Guide

## Prerequisites
- App must be built and running on a device or emulator
- Have test accounts for both Citizen and Police roles

## Test Scenarios

### ✅ Test 1: Citizen Logged In → Police Login → Back
**Steps**:
1. Login as a Citizen user (using phone login or email)
2. You should be on the AI Legal Guide screen
3. Navigate to Welcome screen (you can logout and login again, or manually navigate)
4. From Welcome screen, tap "Login" → Select "Police"
5. You're now on the Police Login screen
6. **Press the back button** (top-left arrow)

**Expected Result**: 
- Should navigate to Welcome screen
- Welcome screen should show "Go to Dashboard" button (because you're logged in as Citizen)
- Should NOT automatically redirect to AI Legal Guide

**How to verify it's fixed**:
- If you see the Welcome screen with "Go to Dashboard" button → ✅ FIXED
- If you're automatically redirected to AI Legal Guide → ❌ STILL BROKEN

---

### ✅ Test 2: Police Logged In → Citizen Login → Back
**Steps**:
1. Login as a Police user
2. You should be on the Police Dashboard
3. Navigate to Welcome screen (logout and go to welcome, or use navigation)
4. From Welcome screen, tap "Login" → Select "Citizen"
5. You're now on the Citizen Login screen (email login)
6. **Press the back button** (top-left arrow)

**Expected Result**: 
- Should navigate to Welcome screen
- Welcome screen should show "Go to Dashboard" button (because you're logged in as Police)
- Should NOT automatically redirect to Police Dashboard

**How to verify it's fixed**:
- If you see the Welcome screen with "Go to Dashboard" button → ✅ FIXED
- If you're automatically redirected to Police Dashboard → ❌ STILL BROKEN

---

### ✅ Test 3: Unauthenticated User → Any Login → Back
**Steps**:
1. Make sure you're logged out
2. From Welcome screen, tap "Login" → Select any role (Citizen or Police)
3. You're now on a Login screen
4. **Press the back button** (top-left arrow)

**Expected Result**: 
- Should navigate to Welcome screen
- Welcome screen should show "Login" and "Register" buttons (because you're not logged in)

**How to verify**:
- If you see the Welcome screen with "Login" and "Register" buttons → ✅ CORRECT
- Any other behavior → ❌ BROKEN

---

### ✅ Test 4: OTP Verification → Back
**Steps**:
1. Start a phone number registration or login flow
2. Enter phone number and request OTP
3. You're now on the OTP Verification screen
4. **Press the back button** (top-left arrow - newly added)

**Expected Result**: 
- Should navigate to Welcome screen
- Should show appropriate buttons based on authentication state

**How to verify**:
- If you see the back button and it works → ✅ FIXED
- If there's no back button → ❌ STILL BROKEN

---

### ✅ Test 5: Go to Dashboard Button (Authenticated Users)
**Steps**:
1. Login as any user (Citizen or Police)
2. Navigate to Welcome screen (you can do this by pressing back from a login screen as tested above)
3. You should see a "Go to Dashboard" button
4. **Tap the "Go to Dashboard" button**

**Expected Result**: 
- If logged in as Citizen → Navigate to AI Legal Guide
- If logged in as Police → Navigate to Police Dashboard

**How to verify**:
- Button navigates to correct dashboard based on role → ✅ CORRECT
- Button doesn't exist or navigates to wrong place → ❌ BROKEN

---

### ✅ Test 6: Session Restoration (Existing Functionality)
**Steps**:
1. Login as any user
2. Navigate to any screen within the app
3. **Close the app completely** (swipe away from recent apps)
4. **Reopen the app**

**Expected Result**: 
- Should restore to the last screen you were on (if session is still valid)
- Should NOT go to Welcome screen on app reopen

**How to verify**:
- App restores to last screen → ✅ EXISTING FUNCTIONALITY PRESERVED
- App goes to Welcome screen → ❌ REGRESSION

---

### ✅ Test 7: Expired Session Handling
**Steps**:
1. Login as any user
2. Wait for session to expire (3 hours) OR manually clear session data
3. **Reopen the app or navigate**

**Expected Result**: 
- Should redirect to Welcome screen or Login screen
- Should NOT crash or show errors

**How to verify**:
- Graceful handling of expired session → ✅ EXISTING FUNCTIONALITY PRESERVED
- Crashes or errors → ❌ REGRESSION

---

### ✅ Test 8: Role-Based Access Control (Existing Functionality)
**Steps**:
1. Login as Citizen
2. Try to manually navigate to a Police-only route (e.g., `/police-dashboard`)
3. Repeat with Police user trying to access Citizen-only routes

**Expected Result**: 
- Should be redirected to appropriate dashboard
- Should NOT be able to access routes for other roles

**How to verify**:
- Access control still works → ✅ EXISTING FUNCTIONALITY PRESERVED
- Can access wrong role's routes → ❌ REGRESSION

---

## Quick Verification Checklist

After implementing the fix, verify these key points:

- [ ] Citizen logged in → Police login → back → Welcome screen (not AI Legal Guide)
- [ ] Police logged in → Citizen login → back → Welcome screen (not Police Dashboard)
- [ ] Welcome screen shows "Go to Dashboard" for authenticated users
- [ ] Welcome screen shows "Login/Register" for unauthenticated users
- [ ] "Go to Dashboard" button works correctly for both roles
- [ ] OTP screen has a back button
- [ ] Session restoration still works on app reopen
- [ ] Role-based access control still works
- [ ] No crashes or errors in any flow

## Common Issues

### Issue: Welcome screen immediately redirects to dashboard
**Cause**: Router redirect logic not properly removed
**Fix**: Check `app_router.dart` lines 116-119, ensure the auto-redirect is commented out

### Issue: "Go to Dashboard" button not showing
**Cause**: Welcome screen not checking authentication state
**Fix**: Check `welcome_screen.dart`, ensure `authProvider.isAuthenticated` check is present

### Issue: Back button still causes cross-role redirections
**Cause**: Login screen back button still using `maybePop()` logic
**Fix**: Check login screen files, ensure back button uses `context.go('/')`

## Success Criteria

The fix is successful if:
1. ✅ All cross-role redirections are eliminated
2. ✅ Back button always goes to Welcome screen from login screens
3. ✅ Welcome screen adapts to authentication state
4. ✅ All existing functionality (session restoration, access control) is preserved
5. ✅ No new crashes or errors introduced

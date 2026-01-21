# 🚔 Offline Petition Submission & Assignment Feature

## Project: Dharma-CMS (Citizen Management System)

---

## 📖 Overview

This feature enables **high-level police officers (SP-level and above)** to digitize offline complaints received from citizens in physical form and efficiently assign them to lower-level officers for investigation and action.

### Key Benefits
- ✅ **Digitizes offline complaints** - No more paper-based tracking
- ✅ **Efficient assignment** - Smart officer selection based on rank and jurisdiction
- ✅ **Better accountability** - Track who submitted, who assigned, who's working on it
- ✅ **Faster processing** - Direct assignment reduces bureaucratic delays
- ✅ **Complete audit trail** - Every action is logged with timestamps

---

## 🎯 Target Users

### Primary Users (Can Submit & Assign)
- Superintendent of Police (SP)
- Additional Superintendent of Police (Addl. SP)
- Inspector General of Police (IGP)
- Deputy Inspector General of Police (DIG)
- Director General of Police (DGP)
- Additional Director General of Police (Addl. DGP)

### Secondary Users (Receive Assignments)
- Deputy Superintendent of Police (DSP)
- Inspector of Police
- Sub Inspector of Police (SI)
- Assistant Sub Inspector of Police (ASI)
- Head Constable
- Police Constable

---

## 📁 Documentation

We've created comprehensive documentation for this feature:

### 1. [Implementation Plan](OFFLINE_PETITION_ASSIGNMENT_FEATURE.md)
Detailed technical specification including:
- Database schema
- Component architecture
- Permission matrix
- Security considerations
- Future enhancements

### 2. [Implementation Summary](OFFLINE_PETITION_IMPLEMENTATION_SUMMARY.md)
Comprehensive guide including:
- Files created/modified
- Usage instructions
- Testing checklist
- Troubleshooting guide
- Developer notes

### 3. [Quick Reference](OFFLINE_PETITION_QUICK_REFERENCE.md)
At-a-glance reference with:
- Feature checklist
- Visual indicators
- Workflow steps
- Testing scenarios
- Common issues

### 4. [Visual Architecture](OFFLINE_PETITION_VISUAL_ARCHITECTURE.md)
Detailed diagrams showing:
- System architecture
- Data flow
- State machine
- Component hierarchy
- User journeys

---

## 🚀 Quick Start

### For SP-Level Officers (Submitting)

1. **Login** to the police dashboard
2. **Click** "Submit Offline Petition" (teal colored card, first position)
3. **Fill** the petition form with details from the citizen's complaint
4. **Upload** documents/images received from the citizen
5. **(Optional)** Assign immediately to a lower-level officer
6. **Submit** the petition

### For Lower-Level Officers (Receiving)

1. **Navigate** to Petitions screen
2. **Go to** "Assigned to Me" tab
3. **Review** the assigned petition
4. **Accept** or **Reject** the assignment
5. **Work** on the case if accepted

---

## 📦 What's Included

### New Screens
- ✅ Submit Offline Petition Screen
- ✅ Assigned Petitions Tab

### New Components
- ✅ Officer Selection Dialog
- ✅ Assigned Petition Card

### Modified Files
- ✏️ `petition.dart` - Added offline & assignment fields
- ✏️ `dashboard_body.dart` - Added quick action button
- ✏️ `app_router.dart` - Added routing

### Documentation
- 📄 4 comprehensive markdown documents
- 📊 Visual diagrams and flowcharts
- ✅ Testing checklists
- 🔍 Troubleshooting guides

---

## 🛠️ Technical Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Storage)
- **State Management**: Provider
- **Routing**: go_router
- **File Handling**: file_picker
- **UI**: Material Design

---

## 📋 Feature Checklist

### Core Features ✅
- [x] Petition submission form with all fields
- [x] Document upload (PDF, Images)
- [x] Officer selection with search & filtering
- [x] Rank-based access control
- [x] Assignment tracking & status management
- [x] Accept/Reject workflow
- [x] Real-time updates

### Security ✅
- [x] Route protection
- [x] Rank-based visibility
- [x] Secure file uploads
- [x] Input validation

### Pending 🔄
- [ ] Firestore security rules deployment
- [ ] Push notifications
- [ ] Email notifications
- [ ] Comprehensive testing
- [ ] User training

---

## 🔐 Security & Permissions

### Access Control Levels

| Level | Submit Offline | Assign | View District | View State |
|-------|---------------|--------|---------------|------------|
| State (DGP+) | ✅ | ✅ | ✅ | ✅ |
| Range (IGP+) | ✅ | ✅ | ✅ | ✅ (Range) |
| District (SP+) | ✅ | ✅ | ✅ | ❌ |
| Station | ❌ | ❌ | ❌ | ❌ |

### Data Privacy
- Officers can only assign to officers in their jurisdiction
- Only authorized ranks can access submission feature
- All actions are logged with officer details
- Secure document storage in Firebase

---

## 🧪 Testing

### Test Scenarios

1. **Submit Offline Petition**
   - Login as SP → Submit petition → Verify creation

2. **Assign Petition**
   - Submit petition → Select officer → Verify assignment

3. **Accept Assignment**
   - Login as assigned officer → Accept → Verify status

4. **Reject Assignment**
   - Login as assigned officer → Reject → Verify status

5. **Access Control**
   - Login as lower rank → Verify button not visible

### Expected Behavior
- ✅ SP+ officers see the submit button
- ✅ Lower rank officers don't see the submit button
- ✅ Officer selection shows only lower ranks
- ✅ Documents upload successfully
- ✅ Assignments update in real-time
- ✅ Status changes reflect immediately

---

## 📊 Data Model

### Key Fields Added to Petition

```dart
// Offline Submission
submissionType: 'offline'
submittedBy: 'officer-uid'
submittedByName: 'Officer Name'
submittedByRank: 'Superintendent of Police'

// Assignment
assignedTo: 'officer-uid'
assignedToName: 'Officer Name'
assignedToRank: 'Sub Inspector of Police'
assignedToStation: 'Station Name'
assignedBy: 'assigning-officer-uid'
assignedByName: 'Assigning Officer'
assignedAt: Timestamp
assignmentStatus: 'pending' | 'accepted' | 'rejected'
assignmentNotes: 'Optional notes'
```

---

## 🎨 UI/UX Highlights

### Visual Indicators
- **OFFLINE Badge** (Orange) - Shows petition was submitted offline
- **ASSIGNED Badge** (Blue) - Shows petition is assigned
- **Status Dots** - Color-coded status (Pending/Accepted/Rejected)

### User Experience
- Clean, intuitive forms
- Real-time feedback
- Smart search and filters
- Responsive design
- Minimal clicks to complete tasks

---

## 🔮 Future Enhancements

### Planned Features
1. **Push Notifications** - Instant alerts for assignments
2. **Bulk Assignment** - Assign multiple petitions at once
3. **Workload Dashboard** - View officer workload before assigning
4. **Reassignment** - Transfer cases between officers
5. **Assignment Reports** - Analytics on assignment patterns
6. **Mobile Optimization** - Enhanced mobile interface
7. **Offline Mode** - Submit without internet, sync later
8. **OCR Integration** - Auto-extract text from scanned documents

---

## 🆘 Support

### Common Issues

**Q: I don't see the "Submit Offline Petition" button**  
A: Ensure you are logged in as SP-level or above officer

**Q: The officer list is empty**  
A: Ensure officers are registered in police_users collection with correct ranks

**Q: Document upload fails**  
A: Check file format (PDF, JPG, PNG) and size (max 10MB)

### Getting Help
- Check [Troubleshooting Guide](OFFLINE_PETITION_IMPLEMENTATION_SUMMARY.md#support--troubleshooting)
- Review [Quick Reference](OFFLINE_PETITION_QUICK_REFERENCE.md)
- Check [Visual Architecture](OFFLINE_PETITION_VISUAL_ARCHITECTURE.md)

---

## 👥 Contributors

**Development Team**: Dharma-CMS Development Team  
**Version**: 1.0  
**Last Updated**: January 2026  
**Status**: ✅ Ready for Testing

---

## 📜 License

This feature is part of the Dharma-CMS project.  
All rights reserved.

---

## 🙏 Acknowledgments

Special thanks to:
- The Andhra Pradesh Police Department for requirements
- The development team for implementation
- Testing team for quality assurance

---

## 📞 Contact

For questions or support regarding this feature:
- Email: [support@dharma-cms.com]
- Documentation: See above links
- Issue Tracker: [GitHub Issues]

---

**Made with ❤️ for better police-citizen interaction**

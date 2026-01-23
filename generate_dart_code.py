#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Add case detail localization implementations to dart files"""

import json

# Load translations
with open('frontend/lib/l10n/app_en.arb', 'r', encoding='utf-8') as f:
    en_data = json.load(f)

with open('frontend/lib/l10n/app_te.arb', 'r', encoding='utf-8') as f:
    te_data = json.load(f)

# Case detail screen keys
case_detail_keys = [
    'firDetails', 'crimeScene', 'investigation', 'evidence', 'finalReport',
    'editCase', 'caseInformation', 'firNumber', 'year', 'complaintId',
    'firDate', 'firFiledAt', 'policeStation', 'occurrenceOfOffence',
    'dayOfOccurrence', 'from', 'to', 'timePeriod', 'priorToDateTimeDetails',
    'beatNumber', 'streetVillage', 'areaMandal', 'cityDistrict', 'pin',
    'latitude', 'longitude', 'distanceFromPS', 'directionFromPS',
    'outsideJurisdiction', 'informationReceivedAtPS', 'dateTimeReceived',
    'gdEntryNo', 'typeOfInformation', 'complainantInformantDetails', 'name',
    'fatherHusbandName', 'dob', 'nationality', 'caste', 'occupation',
    'mobileNumber', 'address', 'passportNo', 'passportPlaceOfIssue',
    'passportDateOfIssue', 'victimDetails', 'religion', 'complainantAlsoVictim',
    'accusedDetails', 'accused', 'propertiesDelayInquest', 'propertiesInvolved',
    'totalValueINR', 'delayInReporting', 'inquestReportCaseNo', 'actsStatement',
    'actsAndSectionsInvolved', 'complaintStatement', 'briefIncidentDetails',
    'actionTakenAndConfirmation', 'actionTaken', 'investigatingOfficer', 'rank',
    'dispatchToCourtDateTime', 'dispatchingOfficer', 'dispatchingOfficerRank',
    'firReadAndAdmittedCorrect', 'copyGivenFreeOfCost', 'roacRecorded',
    'signatureThumbImpression', 'yes', 'no', 'crimeScenes', 'addScene',
    'noCrimeScenesLinked', 'unknownType', 'deleteScene', 'areSureDeleteScene',
    'place', 'physicalEvidence', 'recorded', 'captureCrimeSceneEvidence',
    'photo', 'video', 'upload', 'evidenceFiles', 'analyzeSceneWithAI',
    'analyzing', 'aiSceneAnalysis', 'crimeSceneAnalysisReports',
    'noAnalysisReportsFound', 'caseJournalIOsDiary', 'noJournalEntriesYet',
    'crimeSceneCaptures', 'fromInvestigationDiary', 'fromPetitions',
    'forensicAnalysisReports', 'noEvidenceDocumentsFound',
    'attachedDocumentsWillAppearHere', 'noDocumentsAttachedJournal',
    'noPetitionDocumentsLinked', 'finalInvestigationReport', 'generatedOn',
    'noFinalReportAttached', 'onceSomeoneGeneratesReport',
    'courtReadyReportGenerated', 'downloadViewFinalReportPDF',
    'loadingEvidenceFromAllSources', 'addCrimeScene', 'editCrimeScene',
    'crimeType', 'placeDescription', 'physicalEvidenceDescription', 'cancel',
    'save', 'crimeSceneAdded', 'crimeSceneUpdated', 'errorSavingCrimeScene',
    'delete', 'uploadingCapturedEvidence', 'failedUploadEvidence',
    'geoTaggedPhotoCaptured', 'geoTaggedVideoCaptured', 'uploadEvidence',
    'chooseFileType', 'image', 'document', 'uploadingDocument',
    'failedUploadDocument', 'documentUploaded', 'imageUploaded', 'videoUploaded',
    'errorUploadingFile', 'pleaseCapturUploadEvidenceFirst',
    'sceneAnalysisComplete', 'analysisError', 'downloadEvidence',
    'saveToDeviceDownloads', 'analyzeWithAI', 'getForensicAnalysis',
    'downloadReport', 'deleteReport', 'deleteReportConfirmation', 'reportDeleted',
    'errorDeletingReport', 'generatingPDF', 'errorDownloadingPDF', 'analyzedOn',
    'identifiedElements', 'sceneNarrative', 'caseFileSummary', 'filedOn',
    'accessViaFileManager', 'evidenceDownloaded', 'savedTo', 'downloadFailed',
    'analysisComplete', 'analysisErrorEvidence', 'evidenceRemoved'
]

def escape_dart_string(s):
    """Escape string for Dart single quotes"""
    s = s.replace("\\", "\\\\")  # Escape backslashes first
    s = s.replace("'", "\\'")    # Escape single quotes
    return s

# Generate abstract getters for app_localizations.dart
abstract_code = []
for key in case_detail_keys:
    abstract_code.append(f"  /// Label for {key}")
    abstract_code.append(f"  String get {key};")
    abstract_code.append("")

# Generate English implementations
en_impl_code = []
for key in case_detail_keys:
    if key in en_data:
        value = escape_dart_string(en_data[key])
        en_impl_code.append(f"  @override")
        en_impl_code.append(f"  String get {key} => '{value}';")
        en_impl_code.append("")

# Generate Telugu implementations  
te_impl_code = []
for key in case_detail_keys:
    if key in te_data:
        value = escape_dart_string(te_data[key])
        te_impl_code.append(f"  @override")
        te_impl_code.append(f"  String get {key} => '{value}';")
        te_impl_code.append("")

# Write to text files for manual inspection
with open('abstract_getters.txt', 'w', encoding='utf-8') as f:
    f.write("\n".join(abstract_code))

with open('english_implementations.txt', 'w', encoding='utf-8') as f:
    f.write("\n".join(en_impl_code))

with open('telugu_implementations.txt', 'w', encoding='utf-8') as f:
    f.write("\n".join(te_impl_code))

print(f"Generated abstract getters: {len(case_detail_keys)} keys")
print(f"Generated English implementations: {len([k for k in case_detail_keys if k in en_data])} keys")
print(f"Generated Telugu implementations: {len([k for k in case_detail_keys if k in te_data])} keys")
print("\nFiles created:")
print("  - abstract_getters.txt")
print("  - english_implementations.txt")
print("  - telugu_implementations.txt")

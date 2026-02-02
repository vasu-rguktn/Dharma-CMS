#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Generate and add localization implementations"""

import json

# Load the translations
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

# Generate English implementations
print("// English implementations for case_detail_screen.dart:\n")
en_impl = []
for key in case_detail_keys:
    if key in en_data:
        value = en_data[key].replace('"', '\\"').replace("'", "\\'")
        en_impl.append(f"  @override\n  String get {key} => '{value}';")

print("\n".join(en_impl))

print("\n\n// Telugu implementations:\n")

# Generate Telugu implementations
te_impl = []
for key in case_detail_keys:
    if key in te_data:
        value = te_data[key].replace('"', '\\"')
        # Escape single quotes
        value = value.replace("'", "\\'")
        te_impl.append(f"  @override\n  String get {key} => '{value}';")

print("\n".join(te_impl))

print(f"\n\nTotal keys to add: {len(case_detail_keys)}")
print(f"English keys found: {sum(1 for k in case_detail_keys if k in en_data)}")
print(f"Telugu keys found: {sum(1 for k in case_detail_keys if k in te_data)}")

#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Generate localization getter declarations for app_localizations.dart"""

keys = [
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

# Generate abstract getters
print("// Add these abstract getters to app_localizations.dart:\n")
for key in keys:
    print(f"  /// The label for {key}")
    print(f"  String get {key};\n")

#!/usr/bin/env python3
import re

# List of keys that were added for case_detail_screen
new_keys = [
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

def find_and_remove_duplicates(file_path):
    """Find duplicate getter definitions in AppLocalizationsEn class"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        lines = content.split('\n')
    
    # Find all getter definitions with line numbers
    getter_lines = {}
    for i, line in enumerate(lines):
        match = re.search(r'String get (\w+)\s*=>', line)
        if match:
            getter_name = match.group(1)
            if getter_name not in getter_lines:
                getter_lines[getter_name] = []
            getter_lines[getter_name].append((i+1, line.strip()))  # 1-indexed
    
    # Find duplicates
    duplicates = {k: v for k, v in getter_lines.items() if len(v) > 1}
    
    if duplicates:
        print(f"Found {len(duplicates)} duplicate getters:")
        for getter, occurrences in sorted(duplicates.items()):
            print(f"\n  {getter}:")
            for line_num, line_text in occurrences:
                print(f"    Line {line_num}: {line_text[:80]}")
    else:
        print("No duplicates found")
    
    # Find getters that appear only in new_keys (these are from case_detail)
    new_only = [k for k in new_keys if k in duplicates]
    print(f"\nDuplicate case_detail keys: {len(new_only)}")
    for k in new_only[:5]:
        print(f"  - {k}")
    print(f"  ... and {len(new_only)-5} more" if len(new_only) > 5 else "")
    
    return duplicates

# Check English file
print("=== English File ===")
en_dups = find_and_remove_duplicates('frontend/lib/l10n/app_localizations_en.dart')

print("\n=== Telugu File ===")
te_dups = find_and_remove_duplicates('frontend/lib/l10n/app_localizations_te.dart')

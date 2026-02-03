$excelFile = "c:\Users\APSSDC\Desktop\main\Dharma-Police\Dharma-CMS\police-frontend\assets\Data\Revised AP Police Organisation 31-01-26.xlsx"
$csvFile = "c:\Users\APSSDC\Desktop\main\Dharma-Police\Dharma-CMS\police-frontend\hierarchy_export.csv"

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

$workbook = $excel.Workbooks.Open($excelFile)
$worksheet = $workbook.Sheets.Item(1)

$worksheet.SaveAs($csvFile, 6) # 6 = xlCSV

$workbook.Close()
$excel.Quit()

[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
Write-Host "Exported to $csvFile"

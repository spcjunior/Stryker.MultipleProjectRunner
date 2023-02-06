$Tab = [char]9

function LogInfo () { 
    $timeNow = Get-Date -Format "HH:mm:ss"
    $timeFormat = "[$timeNow INF] "
    Write-Host $timeFormat -NoNewLine
}

function RunForOneAssembly ($csprojName, $solutionName, $testDir, $sourcePath, $outputPath) {    
    
    $testPath = "$sourcePath\$testDir"
    $solutionPath = "..\$solutionName"  

    Set-Location $testPath    

    LogInfo; 
    Write-Host "Project " -NoNewLine;
    Write-Host $csprojName -ForegroundColor Cyan -NoNewLine;
    Write-Host " TestDir " -NoNewLine;
    Write-Host $testPath -ForegroundColor Cyan

    dotnet stryker --project "$csprojName" --solution $solutionPath --reporter "json" -r "progress"

    $searchPath = "..\$testDir"    

    # find all json result files and use the most recent one
    $files = Get-ChildItem -Path "$searchPath"  -Filter "*.json" -Recurse -ErrorAction SilentlyContinue -Force
    $file = $files | Sort-Object { $_.LastWriteTime } | Select-Object -last 1
          
    # get the name and the timestamp of the file
    $orgReportFilePath = $file.FullName
    $splitted = $splitted = $orgReportFilePath.split("\")
    $dateTimeStamp = $splitted[$splitted.Length - 3]
    $fileName = $splitted[$splitted.Length - 1]

    LogInfo; 
    Write-Host "Getting results in " -NoNewline; 
    Write-Host $orgReportFilePath -ForegroundColor Cyan;    
        
    # create a new filename to use in the output
    $newFileName = "$outputPath" + $dateTimeStamp + "_" + $fileName    
    # write the new file out to the report directory
    Copy-Item "$orgReportFilePath" "$newFileName"
}

function JoinStykerJsonFile ($additionalFile, $joinedFileName) {
    # Stryker report json files object is not an array :-(, so we cannot join them and have to do it manually
    $report = (Get-Content $joinedFileName | Out-String)
    $additionalContent = (Get-Content $additionalFile | Out-String)

    $searchString = '"files":{'
    $searchStringLength = $searchString.Length
    $startCopy = $additionalContent.IndexOf($searchString)
    $offSet = 4    
    $copyText = $additionalContent.Substring($startCopy + $searchStringLength, $additionalContent.Length - $offSet - $startCopy - $searchStringLength)             

    # save the first part of the report file
    $startCopy = $report.Substring(0, $report.Length - $offSet)    

    # add in the new copy text
    $startCopy = $startCopy + ",`r`n" + $copyText
    
    # add in the end of the file again
    $fileEnding = $report.Substring($report.Length - $offSet, $offSet)
    $startCopy = $startCopy + $fileEnding

    # save the new file to disk
    Set-Content -Path $joinedFileName -Value $startCopy
}

function JoinJsonWithHtmlFile ($joinedJsonFileName, $reportFileName, $emptyReportFileName, $reportTitle) {

    if ((Test-Path $joinedJsonFileName -PathType Leaf)) {
        $report = (Get-Content $emptyReportFileName | Out-String)
        $Json = (Get-Content $joinedJsonFileName | Out-String)
    
        $dateReport = Get-Date
        $report = $report.Replace("##REPORT_JSON##", $Json)
        $report = $report.Replace("##REPORT_TITLE##", $reportTitle)
        $report = $report.Replace("##REPORT_DATE##", $dateReport)

        # hardcoded link to the package from the npm CDN
        $report = $report.Replace("<script>##REPORT_JS##</script>", '<script defer src="https://www.unpkg.com/mutation-testing-elements"></script>')
            
        Set-Content -Path $reportFileName -Value $report
    }   
}

function JoinAllJsonFiles ($joinedFileName) {
    $files = Get-ChildItem  -Filter "*.json" -Exclude $joinedFileName -Recurse -ErrorAction SilentlyContinue -Force    
    $firstFile = $true
    foreach ($file in $files) {
        if ($true -eq $firstFile) {
            # copy the first file as is
            Copy-Item $file.FullName "$joinedFileName"
            $firstFile = $false
            continue
        }

        JoinStykerJsonFile $file.FullName $joinedFileName
    }
    LogInfo; Write-Host "$($files.Count) results found and merged";
}

function LoadConfigurationFile ($startDir) {  

    LogInfo; Write-Host "Starting in$Tab$Tab$Tab$Tab" -NoNewline; Write-Host $startDir -ForegroundColor Cyan

    # try to load given file    
    $strykerConfigFile = "$startDir\stryker-config.json" 
    LogInfo; Write-Host "Looking for 'stryker-config.json' in$Tab" -NoNewLine; Write-Host $strykerConfigFile -ForegroundColor Cyan

    if (!(Test-Path $strykerConfigFile -PathType Leaf)) {
        LogInfo; Write-Host "stryker-config.json not found" -ForegroundColor Red;
        exit;
    } 

    # load the data file
    $strykerData = (Get-Content $strykerConfigFile | Out-String | ConvertFrom-Json)  
        
    # check if parameter 'sourcePath' was fill
    if ([string]::IsNullOrEmpty($strykerData.sourcePath)) {
        LogInfo; Write-Host "Parameter 'sourcePath' not found in 'stryker-config.json'" -ForegroundColor Red;
        exit;
    } 

    # check if parameter 'solutionName' was fill
    if ([string]::IsNullOrEmpty($strykerData.solutionName)) {
        LogInfo; Write-Host "Parameter 'solutionName' not found in 'stryker-config.json'" -ForegroundColor Red;
        exit;
    } 
    
    $solutionPath = "$($strykerData.sourcePath)\$($strykerData.solutionName)";    
    # check if SolutionPath exist
    if (!(Test-Path $solutionPath -PathType Leaf)) {
        LogInfo; Write-Host "Solution path not found '$solutionPath'" -ForegroundColor Red;
        exit;
    } 
    # add solutionPath as parameter in $strykerData object
    $strykerData | Add-Member -NotePropertyName solutionPath -NotePropertyValue $solutionPath   
  
    # add jsonReportsPath as parameter in $strykerData object
    $local = Get-Location
    $strykerData | Add-Member -NotePropertyName jsonReportsPath -NotePropertyValue "$local\StrykerOutput\"  

    # check if parameter 'projectsToTest' was fill
    if ($null -eq $strykerData.projectsToTest) {
        LogInfo; Write-Host "Parameter 'projectsToTest' not configured in 'stryker-config.json'" -ForegroundColor Red;        
    } 

    $outputPath = "$($strykerData.jsonReportsPath)"
    # create a new directory for the output if needed   
    New-Item $outputPath -ItemType "directory" -Force
    
    # create a .gitignore
    New-Item $outputPath".gitignore" -ItemType "file" -Value "*" -Force

    return $strykerData
}

function DeletePreviousResults ($strykerData) {
    if (!$strykerData) {
        Write-Error "Cannot delete from unknown directory"
        return
    }
    # clear the output path
    LogInfo; Write-Host "Deleting previous results *.json in$Tab" -NoNewline; Write-Host $($strykerData.jsonReportsPath) -ForegroundColor Cyan
    Get-ChildItem -Path "$($strykerData.jsonReportsPath)" -Include *.json -File -Recurse | ForEach-Object { $_.Delete() }
}

function MutateAllAssemblies($strykerData, $startDir) {
    $counter = 1
    $total = $strykerData.projectsToTest.Length
    foreach ($project in $strykerData.projectsToTest) {
        LogInfo; 
        Write-Host "Project " -NoNewline; 
        Write-Host "$($counter)" -NoNewline -ForegroundColor Magenta; 
        Write-Host " of " -NoNewline;
        Write-Host "$($total)" -ForegroundColor Magenta;        

        RunForOneAssembly $project.csprojName $strykerData.solutionName $project.testDir $strykerData.sourcePath $strykerData.jsonReportsPath

        LogInfo; 
        Write-Host "Done" -ForegroundColor Green;        
        $counter++

        Set-Location $startDir
    }
}

function CreateReportFromAllJsonFiles ($reportDir, $startDir) {
    # Join all the json files
    Set-Location "$reportDir"
    $joinedJsonFileName = "mutation-report.json"

    JoinAllJsonFiles $joinedJsonFileName

    # join the json with the html template for the final output
    $emptyReportFileName = "$startDir\StrykerReportEmpty.html"
    if (!(Test-Path $emptyReportFileName -PathType Leaf)) {
        LogInfo; Write-Host "Report tamplate(.html) not found $emptyReportFileName to update results" -ForegroundColor Yellow
        return
    }
    $reportFileName = "StrykerReport.html"  
    $reportTitle = "Stryker Mutation Testing"
    JoinJsonWithHtmlFile $joinedJsonFileName $reportFileName $emptyReportFileName $reportTitle

    LogInfo; Write-Host "Created new report file in " -NoNewline; Write-Host "$reportDir$reportFileName" -ForegroundColor Cyan
}

function RunAllProjects ($startDir) {
    try {             
        $strykerData = LoadConfigurationFile $startDir
                
        #check for errors
        if ( -not $?) {
            exit;
        }

        # clean up previous runs
        DeletePreviousResults $strykerData

        # mutate all projects in the data file
        MutateAllAssemblies $strykerData $startDir

        # check for errors
        if ( -not $?) {
            exit;
        }

        CreateReportFromAllJsonFiles $strykerData.jsonReportsPath $startDir
    }
    finally {
        # change back to the starting directory
        Set-Location $startDir
    }
}


task BuildPackerTemplates {

    $buildFolderPaths = Get-ChildItem  `
        | ?{ $_.PSIsContainer } `
        | ?{ $_.FullName -imatch "win-|ubuntu-" } `
        | Select-Object FullName -ExpandProperty FullName

    $count = $buildFolderPaths.Count;
    $index = 0

    foreach($buildFolderPath in $buildFolderPaths) {
        $index = $index + 1
        $folderName = Split-Path $buildFolderPath -Leaf

        Write-Build Green "[$index/$count] building template: $folderName"
        exec {
            pwsh -c "cd $buildFolderPath; . ./.build.ps1"
        }
    }
}

task . BuildPackerTemplates
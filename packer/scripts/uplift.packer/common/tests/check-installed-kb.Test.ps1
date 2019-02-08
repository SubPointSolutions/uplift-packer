Import-Module Uplift.Core

$kbNames = (Get-UpliftEnvVariable 'UPLF_TEST_KB_NAMES').Split(';')

Describe 'Installed KBs' {

    Context "KB" {

        function CheckFix($name) {
            Get-HotFix | Where-Object HotfixID -match $name | Should Not Be $null
        }

        foreach($kbName in $kbNames) {
            It "$kbName" {
                CheckFix $kbName
            }
        }
    }
}
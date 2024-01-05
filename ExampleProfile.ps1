Import-Module posh-git
Import-Module -Name SqlServer
Import-Module -Name "C:\Repos\PersonalScript\PersonalScript"

$reposDir = "C:\Repos" | Resolve-Path
$env:RedgateSqlMonitorUrl = "https://localhost:4001"
$env:RedgateSqlMonitorAuthToken = "YouWishYouSeeMyToken"
$env:SQLMONITORTEST_LocalAuthToken = $env:RedgateSqlMonitorAuthToken
$instanceName = "DEV-LT-STEFANO2"
$BmPath = "C:\Repos\sqlmonitor\Source\.idea\.idea.RedGate.SqlMonitor\.idea\runConfigurations\BaseService.xml"
$NotionDatabaseID = "YouWishYouSeeMyDatabaseID"
$NotionAPIKey = "secret_IfItIsASecretYouCantSeeIt"

Help

function Invoke-SQMPosh {
    . "C:\Repos\sqlmonitor\scripts\BootstrapSqlMonitor.ps1"
}

function Start-SQMPester {
    . "C:\Repos\sqlmonitor\ApiPowershellTests\DownloadAndExtractSqlMonitorModule.ps1 local"
    Import-Module "C:\Repos\sqlmonitor\ApiPowershellTests\Setup.ps1 -ArgumentList local"
}
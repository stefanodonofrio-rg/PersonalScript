Import-Module -Name SqlServer

function Help {
    Write-Host "Personal available commands:"
    Write-Host "1- Invoke-SQMPosh"
    Write-Host "2- Start-SQMPester"
    Write-Host "3- Set-Bm"
    Write-Host "4- Get-Dbs"
    Write-Host "5- New-Db"
    Write-Host "6- Remove-Db"
    Write-Host "7- Backup-Db"
    Write-Host "8- Restore-Db"
    Write-Host "9- Add-Note"
    Write-Host "10- Start-Aspire"
}

function Start-Aspire{
    docker run --rm -it -p 18888:18888 -p 4317:18889 -d --name aspire-dashboard -e DOTNET_DASHBOARD_UNSECURED_ALLOW_ANONYMOUS='true' mcr.microsoft.com/dotnet/nightly/aspire-dashboard
}

function Add-Note {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $Text,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string] $Title
    )

    $finalTitle = (Get-Date).ToString("yyyy-MM-dd-HH:mm:ss")
    if ([string]::IsNullOrEmpty($Title) -eq $false) {
        $finalTitle = "$finalTitle-$Title"
    }

    $Notionheaders = @{
        "Authorization"  = "Bearer $NotionAPIKey"
        "Content-type"   = "application/json"
        "Notion-Version" = "2021-08-16"
    }

    $JsonBody = @"
    {
        "parent": { "page_id": "$NotionDatabaseID" },
        "properties": {
            "title": {
          "title": [{ "type": "text", "text": { "content": "$finalTitle" } }]
            }
        },
        "children": [
        {
          "object": "block",
          "type": "paragraph",
          "paragraph": {
            "rich_text": [{ "type": "text", "text": { "content": "$Text" } }]
          }
        }
      ]
    }
"@

    $Return = Invoke-RestMethod -Uri "https://api.notion.com/v1/pages" -Method POST -Headers $Notionheaders -Body $JsonBody
}

function Set-Bm {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $Name
    )
    $NewProgramArgument = "--port 7397 --repository-connection-string `"Data Source=localhost; Initial Catalog=$($name); Integrated Security=true; Application Name=SQL Monitor - Repository;`""
    [xml]$xmlDoc = Get-Content -Path $BmPath
    $xmlDoc.component.configuration.option[1].value = $NewProgramArgument
    $xmlDoc.Save($BmPath)
}

function Get-Dbs {
    $sqlScript = "SELECT name FROM master.sys.databases WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb')"
    $dbs = Invoke-SqlCmd -ServerInstance $instanceName -Query $sqlScript -TrustServerCertificate
    foreach ($db in $dbs) {
        Write-Output $db.name
    }
}

function New-Db {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]] $Names,
        [switch]
        $UpdateBm
    )
    foreach ($Name in $Names) {
        try {
            $sqlScript = "CREATE DATABASE [$($Name)]
        CONTAINMENT = NONE
        ON  PRIMARY 
       ( NAME = N'$($Name)', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\$($Name).mdf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
        LOG ON 
       ( NAME = N'$($Name)_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\$($Name)_log.ldf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
       GO
       ALTER DATABASE [$($Name)] SET COMPATIBILITY_LEVEL = 150
       GO
       ALTER DATABASE [$($Name)] SET ANSI_NULL_DEFAULT OFF 
       GO
       ALTER DATABASE [$($Name)] SET ANSI_NULLS OFF 
       GO
       ALTER DATABASE [$($Name)] SET ANSI_PADDING OFF 
       GO
       ALTER DATABASE [$($Name)] SET ANSI_WARNINGS OFF 
       GO
       ALTER DATABASE [$($Name)] SET ARITHABORT OFF 
       GO
       ALTER DATABASE [$($Name)] SET AUTO_CLOSE OFF 
       GO
       ALTER DATABASE [$($Name)] SET AUTO_SHRINK OFF 
       GO
       ALTER DATABASE [$($Name)] SET AUTO_CREATE_STATISTICS ON(INCREMENTAL = OFF)
       GO
       ALTER DATABASE [$($Name)] SET AUTO_UPDATE_STATISTICS ON 
       GO
       ALTER DATABASE [$($Name)] SET CURSOR_CLOSE_ON_COMMIT OFF 
       GO
       ALTER DATABASE [$($Name)] SET CURSOR_DEFAULT  GLOBAL 
       GO
       ALTER DATABASE [$($Name)] SET CONCAT_NULL_YIELDS_NULL OFF 
       GO
       ALTER DATABASE [$($Name)] SET NUMERIC_ROUNDABORT OFF 
       GO
       ALTER DATABASE [$($Name)] SET QUOTED_IDENTIFIER OFF 
       GO
       ALTER DATABASE [$($Name)] SET RECURSIVE_TRIGGERS OFF 
       GO
       ALTER DATABASE [$($Name)] SET  DISABLE_BROKER 
       GO
       ALTER DATABASE [$($Name)] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
       GO
       ALTER DATABASE [$($Name)] SET DATE_CORRELATION_OPTIMIZATION OFF 
       GO
       ALTER DATABASE [$($Name)] SET PARAMETERIZATION SIMPLE 
       GO
       ALTER DATABASE [$($Name)] SET READ_COMMITTED_SNAPSHOT OFF 
       GO
       ALTER DATABASE [$($Name)] SET  READ_WRITE 
       GO
       ALTER DATABASE [$($Name)] SET RECOVERY FULL 
       GO
       ALTER DATABASE [$($Name)] SET  MULTI_USER 
       GO
       ALTER DATABASE [$($Name)] SET PAGE_VERIFY CHECKSUM  
       GO
       ALTER DATABASE [$($Name)] SET TARGET_RECOVERY_TIME = 60 SECONDS 
       GO
       ALTER DATABASE [$($Name)] SET DELAYED_DURABILITY = DISABLED 
       GO
       USE [$($Name)]
       GO
       ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = Off;
       GO
       ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET LEGACY_CARDINALITY_ESTIMATION = Primary;
       GO
       ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 0;
       GO
       ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET MAXDOP = PRIMARY;
       GO
       ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SNIFFING = On;
       GO
       ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET PARAMETER_SNIFFING = Primary;
       GO
       ALTER DATABASE SCOPED CONFIGURATION SET QUERY_OPTIMIZER_HOTFIXES = Off;
       GO
       ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET QUERY_OPTIMIZER_HOTFIXES = Primary;
       GO
       USE [$($Name)]
       GO
       IF NOT EXISTS (SELECT name FROM sys.filegroups WHERE is_default=1 AND name = N'PRIMARY') ALTER DATABASE [$($Name)] MODIFY FILEGROUP [PRIMARY] DEFAULT
       GO
       "
            Invoke-SqlCmd -ServerInstance $instanceName -Query $sqlScript -TrustServerCertificate
            if ($UpdateBM.IsPresent) {
                Set-Bm -Name $Name
                Write-Output "Created database $($Name) and updated BM"     
            }
            else {
                Write-Output "Created database $($Name)"
            }
        }
        catch {
            Write-Output "Failed to create database $($Name)"
        }
    }
    
}

function Remove-Db {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]] $Names
    )    
    foreach ($Name in $Names) {
        try {
            $sqlScript = "USE [master]
            GO
            ALTER DATABASE [$($Name)] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
            GO
            
            /* Query to Drop Database in SQL Server  */
            
            DROP DATABASE [$($Name)]"
            invoke-sqlcmd -ServerInstance $instanceName -database master -Query $sqlScript -TrustServerCertificate
            Write-Output "Deleted database $($Name)"
        }
        catch {
            Write-Output "Failed to delete database $($Name)"
            throw
        }
    }
}

function Backup-Db {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]] $Names
    )    
    foreach ($Name in $Names) {
        try {
            Backup-SqlDatabase -ServerInstance $instanceName -Database $Name
            Write-Output "Backed up database $($Name)"
        }
        catch {
            Write-Output "Failed to backup database $($Name)"
            throw
        }
    }
}

function Restore-Db {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]] $Names,

        [switch]
        $UpdateBm
    )    
    foreach ($Name in $Names) {
        try {
            Restore-SqlDatabase -ServerInstance $instanceName -Database $Name
            if ($UpdateBM.IsPresent) {
                Set-Bm -Name $Name
                Write-Output "Restored database $($Name) and updated BM"
            }
            else {
                Write-Output "Restored database $($Name)"
            }
        }
        catch {
            Write-Output "Failed to restore database $($Name)"
            throw
        }
    }
}
$ErrorActionPreference = 'Stop'

function Show-End {
    Write-Host ''
    [void](Read-Host 'Press ENTER to close this window')
}

try {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host 'Administrator access required. Approve the Windows UAC prompt.' -ForegroundColor Yellow
        $argString = '-NoProfile -ExecutionPolicy Bypass -File "' + $PSCommandPath + '"'
        Start-Process -FilePath 'powershell.exe' -ArgumentList $argString -Verb RunAs -Wait
        exit
    }

    Write-Host '====================================================' -ForegroundColor Cyan
    Write-Host ' Russian Trusted CA - Windows certificate cleanup' -ForegroundColor Cyan
    Write-Host '====================================================' -ForegroundColor Cyan
    Write-Host 'Only certificates with matching CN names are selected.'
    Write-Host 'No websites or files are downloaded.'
    Write-Host ''

    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $outputDir = Join-Path $env:USERPROFILE ("Russian_CA_Cleanup_$stamp")
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
    $logFile = Join-Path $outputDir 'result.txt'
    $report = New-Object 'System.Collections.Generic.List[string]'
    $report.Add("Started: $(Get-Date -Format s)")
    $report.Add("Computer: $env:COMPUTERNAME")
    $report.Add("Account: $([Security.Principal.WindowsIdentity]::GetCurrent().Name)")
    $report.Add('Search: CurrentUser and LocalMachine cert stores')

    # Standard stores in which certificates may be manually imported.
    # Disallowed is intentionally excluded: removing a blocked certificate
    # could reverse a safety restriction.
    $storeNames = @('Root', 'CA', 'AuthRoot', 'TrustedPeople', 'TrustedPublisher', 'My', 'WebHosting')
    $locations = @('CurrentUser', 'LocalMachine')
    $candidateCerts = New-Object 'System.Collections.Generic.List[object]'
    $seenPaths = @{}
    # Do not use PowerShell automatic regex variable for this list.

    foreach ($location in $locations) {
        foreach ($storeName in $storeNames) {
            $storePath = "Cert:\$location\$storeName"
            try {
                if (-not (Test-Path -LiteralPath $storePath)) { continue }
                $certificates = @(Get-ChildItem -LiteralPath $storePath -ErrorAction Stop)
                foreach ($cert in $certificates) {
                    # Supports the original RSA and newer CA/GOST versions.
                    # Check the certificate's SUBJECT, not its ISSUER:
                    # do not delete Sberbank/server certificates issued by this CA.
                    if ($cert.Subject -notmatch '(?:^|,\s*)CN\s*=\s*Russian Trusted (?:Root|Sub) CA(?:\b|$)') {
                        continue
                    }
                    $fullPath = "$storePath\$($cert.Thumbprint)"
                    if (-not $seenPaths.ContainsKey($fullPath)) {
                        $seenPaths[$fullPath] = $true
                        $candidateCerts.Add([PSCustomObject]@{
                            Location = $location
                            Store = $storeName
                            Subject = $cert.Subject
                            Thumbprint = $cert.Thumbprint
                            Certificate = $cert
                            Path = $fullPath
                        })
                    }
                }
            }
            catch {
                $line = "SCAN ERROR in ${storePath}: $($_.Exception.Message)"
                Write-Host $line -ForegroundColor Yellow
                $report.Add($line)
            }
        }
    }

    # Refuse deletion if the scan collected malformed results.
    foreach ($item in $candidateCerts) {
        if ([string]::IsNullOrWhiteSpace($item.Subject) -or
            [string]::IsNullOrWhiteSpace($item.Thumbprint) -or
            [string]::IsNullOrWhiteSpace($item.Path) -or
            $null -eq $item.Certificate) {
            throw 'Safety check failed: invalid certificate entry. Nothing has been deleted.'
        }
    }

    Write-Host ("Found: {0} certificate entries" -f $candidateCerts.Count) -ForegroundColor Yellow
    $report.Add("Found: $($candidateCerts.Count)")

    if ($candidateCerts.Count -eq 0) {
        Write-Host ''
        Write-Host 'Nothing matching Russian Trusted Root/Sub CA was found in the scanned stores.' -ForegroundColor Green
        Write-Host 'If certificates were installed into Firefox itself, check its own certificate manager.'
        $report.Add('No matching entries found.')
    }
    else {
        Write-Host ''
        for ($i = 0; $i -lt $candidateCerts.Count; $i++) {
            $m = $candidateCerts[$i]
            Write-Host ("[{0}] {1}\{2}" -f ($i + 1), $m.Location, $m.Store) -ForegroundColor Cyan
            Write-Host ("    Subject: {0}" -f $m.Subject)
            Write-Host ("    SHA-1:   {0}" -f $m.Thumbprint)
            $report.Add("MATCH $($m.Location)\$($m.Store): $($m.Subject) [$($m.Thumbprint)]")
        }
        Write-Host ''
        Write-Host 'Certificates will be backed up as .cer files before deletion.'
        $choice = Read-Host 'Type DELETE to back up and remove the listed entries (anything else cancels)'
        if ($choice -cne 'DELETE') {
            Write-Host 'Cancelled: no certificates were changed.' -ForegroundColor Yellow
            $report.Add('Cancelled by user.')
        }
        else {
            $removed = 0
            $failed = 0
            $backedUp = 0
            for ($i = 0; $i -lt $candidateCerts.Count; $i++) {
                $m = $candidateCerts[$i]
                $safeName = ('{0}_{1}_{2}.cer' -f $m.Location, $m.Store, $m.Thumbprint)
                $backupPath = Join-Path $outputDir $safeName
                try {
                    # Fail closed if a backup cannot be written.
                    Export-Certificate -Cert $m.Certificate -FilePath $backupPath -Type CERT -ErrorAction Stop | Out-Null
                    $backedUp++
                }
                catch {
                    $failed++
                    $line = "SKIPPED (backup failed): $($m.Path) - $($_.Exception.Message)"
                    Write-Host $line -ForegroundColor Red
                    $report.Add($line)
                    continue
                }
                try {
                    Remove-Item -LiteralPath $m.Path -Confirm:$false -ErrorAction Stop
                    $removed++
                    $line = "REMOVED: $($m.Path)"
                    Write-Host $line -ForegroundColor Green
                    $report.Add($line)
                }
                catch {
                    $failed++
                    $line = "FAILED to remove $($m.Path) - $($_.Exception.Message)"
                    Write-Host $line -ForegroundColor Red
                    $report.Add($line)
                }
            }
            Write-Host ''
            Write-Host "Removed: $removed; failed/skipped: $failed; backups: $backedUp" -ForegroundColor Cyan
            $report.Add("Removed=$removed; FailedOrSkipped=$failed; Backups=$backedUp")
            foreach ($m in $candidateCerts) {
                try {
                    if (Test-Path -LiteralPath $m.Path) {
                        $line = "STILL PRESENT: $($m.Path)"
                        Write-Host $line -ForegroundColor Yellow
                        $report.Add($line)
                    }
                }
                catch {
                    $report.Add("CHECK ERROR: $($m.Path) - $($_.Exception.Message)")
                }
            }
        }
    }

    $report.Add("Finished: $(Get-Date -Format s)")
    $report | Out-File -FilePath $logFile -Encoding UTF8
    Write-Host ''
    Write-Host "Report and backups: $outputDir" -ForegroundColor Cyan
    Write-Host 'Close and reopen browsers (and reboot Windows if needed).'
    Write-Host 'Firefox may use its own certificate store.'
    Show-End
}
catch {
    Write-Host ''
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Show-End
    exit 1
}

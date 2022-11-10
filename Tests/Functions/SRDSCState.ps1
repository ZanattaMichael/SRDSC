
Function Backup-SRDSCState {
    if (-not($Global:SRDSC)) { return }
    $Global:BACKUP_SRDSC = $Global:SRDSC.psobject.copy()
}

function Restore-SRDSCState {
    if (-not($Global:BACKUP_SRDSC)) { return }
    $Global:SRDSC = $Global:BACKUP_SRDSC.psobject.copy()
}

Function Backup-SRDSCState {
    $Global:BACKUP_SRDSC = $Global:SRDSC.psobject.copy()
}

function Restore-SRDSCState {
    $Global:SRDSC = $Global:BACKUP_SRDSC.psobject.copy()
}
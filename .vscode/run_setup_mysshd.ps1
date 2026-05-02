param (
    [string]$remoteUser,
    [string]$remotePort,
    [string]$remoteHost,
    [string]$sshdPort
)

# Set-PSDebug -Trace 1

# 1. Upload
Write-Host "--- Uploading setup_my_sshd.sh ... ---" -ForegroundColor Cyan
pscp -P ${remotePort} ".vscode/setup_my_sshd.sh" ${remoteUser}@${remoteHost}:/home/${remoteUser}/.ssh
#pscp -P 10001 setup_my_sshd.sh ost@localhost\:/home/ost/.ssh

if ($LASTEXITCODE -ne 0) {
    Write-Host "RESULT: NOK (Upload Failed)" -ForegroundColor Red
    exit 1
}

# 2. Execute via Plink
Write-Host "--- Executing setup_my_sshd.sh ... ---" -ForegroundColor Cyan
# $RemoteHost = $RemoteTarget.Split(":")[0]
# $RemotePath = $RemoteTarget.Split(":")[1]

plink -batch -P ${remotePort} -l $remoteUser $remoteHost "chmod +x ./setup_my_sshd.sh ; ./setup_my_sshd.sh $sshdPort"
# plink -batch -P ${remotePort} -l ${remoteUser} ${remoteHost} "pwd"

# 3. Check Result
if ($LASTEXITCODE -eq 0) {
    Write-Host "-----------------------"
    Write-Host "RESULT: OK" -ForegroundColor Green
} else {
    Write-Host "-----------------------"
    Write-Host "RESULT: NOK (Execution Failed with code $LASTEXITCODE)" -ForegroundColor Red
    exit 1
}
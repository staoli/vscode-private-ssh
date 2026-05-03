param (
    [string]$remoteUser = "ost",
    [string]$remotePort = "10001",
    [string]$remoteHost = "localhost",
    [string]$remoteHome = "/home/${remoteUser}/.my_sshd",
    [string]$sshdPath = ".my_sshd", 
    # [string]$remoteKeyPath = "/home/${remoteUser}/.my_ssh/authorized_keys",
    [string]$sshdPort = "4444",
    [string]$localKeyPath = "$HOME\.ssh\id_rsa"
    
)

# Set-PSDebug -Trace 1

# 1. Create remote SSHD directory if it doesn't exist
Write-Host "--- Creating $sshdPath on $remoteHost ... ---" -ForegroundColor Cyan
plink -batch -P ${remotePort} -l $remoteUser $remoteHost "mkdir -p $sshdPath"
if ($LASTEXITCODE -ne 0) {
    Write-Host "RESULT: NOK (Creating $sshdPath Failed)" -ForegroundColor Red
    exit 1
}

# 2. Check if the key already exists
if (-not (Test-Path $localKeyPath)) {
    Write-Host "SSH key not found. Generating a new RSA key pair..." -ForegroundColor Cyan
    
    # Create .ssh directory if it doesn't exist
    if (-not (Test-Path "$HOME\.ssh")) {
        New-Item -ItemType Directory -Path "$HOME\.ssh" | Out-Null
    }

    # Generate key (4096 bit for security)
    # -N '' sets an empty passphrase. Remove if you want to be prompted for one.
    ssh-keygen -t rsa -b 4096 -f $localKeyPath -N "''"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "RESULT: NOK (ssh-keygen Failed)" -ForegroundColor Red
        exit 1
    }
}

# 3. Upload key
if (Test-Path $localKeyPath) {
    Write-Host "--- Uploading $localKeyPath to ${remoteUser}@${remoteHost}:${sshdPath}/authorized_keys ... ---" -ForegroundColor Cyan
    # pscp -P ${remotePort} "$localKeyPath" ${remoteUser}@${remoteHost}:${sshdPath}/authorized_keys
    pscp -P ${remotePort} "$localKeyPath.pub" ${remoteUser}@${remoteHost}:${sshdPath}/authorized_keys
    if ($LASTEXITCODE -ne 0) {
        Write-Host "RESULT: NOK (Upload Failed)" -ForegroundColor Red
        exit 1
    }
}

# 4. Upload setup script
Write-Host "--- Uploading setup_my_sshd.sh to ${remoteUser}@${remoteHost}:${sshdPath}... ---" -ForegroundColor Cyan
pscp -P ${remotePort} ".vscode/setup_my_sshd.sh" ${remoteUser}@${remoteHost}:${sshdPath}
if ($LASTEXITCODE -ne 0) {
    Write-Host "RESULT: NOK (Upload Failed)" -ForegroundColor Red
    exit 1
}

# 5. Execute via Plink
Write-Host "--- Executing setup_my_sshd.sh ... ---" -ForegroundColor Cyan
plink -batch -P ${remotePort} -l $remoteUser $remoteHost "ls -la ; ls -la ${sshdPath} ; chmod +x ${sshdPath}/setup_my_sshd.sh ; ls -la ${sshdPath} ; ${sshdPath}/setup_my_sshd.sh $sshdPort '$sshdPath'"
# plink -batch -P ${remotePort} -l ${remoteUser} ${remoteHost} "pwd"
if ($LASTEXITCODE -eq 0) {
    Write-Host "-----------------------"
    Write-Host "RESULT: OK" -ForegroundColor Green
} else {
    Write-Host "-----------------------"
    Write-Host "RESULT: NOK (Execution Failed with code $LASTEXITCODE)" -ForegroundColor Red
    exit 1
}

Write-Host "--- Test the connection ... ---" -ForegroundColor Cyan
# ssh -p ${sshdPort} -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -l $remoteUser $remoteHost "uname -n ; pwd"
ssh -p ${sshdPort} -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -l $remoteUser $remoteHost "uname -n ; pwd"
if ($LASTEXITCODE -eq 0) {
    Write-Host "-----------------------"
    Write-Host "RESULT: OK" -ForegroundColor Green
    exit 0
} else {
    Write-Host "-----------------------"
    Write-Host "RESULT: NOK (Execution Failed with code $LASTEXITCODE)" -ForegroundColor Red
    exit 1
}


# --- Configuration ---
$keyPath = "$HOME\.ssh\id_rsa"
$remoteUser = "username"
$remoteHost = "192.168.1.100"
$remotePath = "/home/$remoteUser/.ssh/authorized_keys"

# 1. Check if the key already exists
if (-not (Test-Path $keyPath)) {
    Write-Host "SSH key not found. Generating a new RSA key pair..." -ForegroundColor Cyan
    
    # Create .ssh directory if it doesn't exist
    if (-not (Test-Path "$HOME\.ssh")) {
        New-Item -ItemType Directory -Path "$HOME\.ssh" | Out-Null
    }

    # Generate key (4096 bit for security)
    # -N '' sets an empty passphrase. Remove if you want to be prompted for one.
    ssh-keygen -t rsa -b 4096 -f $keyPath -N "''"
} else {
    Write-Host "SSH key already exists at $keyPath. Skipping generation." -ForegroundColor Yellow
}

# 2. Copy the Public Key to the remote host using pscp
Write-Host "Transferring public key to $remoteHost..." -ForegroundColor Cyan

# We use the .pub file for the remote server
$pubKeyPath = "$keyPath.pub"

# Command logic:
# -scp: forces SCP protocol
# -pw: (Optional) You can add -pw "password" here, but it's insecure. 
# It's better to let pscp prompt you for the password manually.
pscp -scp $pubKeyPath "${remoteUser}@${remoteHost}:${remotePath}"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Successfully copied key to $remoteHost" -ForegroundColor Green
} else {
    Write-Warning "Failed to copy key. Ensure pscp is installed and the remote path exists."
}
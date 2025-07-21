# SSL Certificates Directory

This directory is for custom SSL certificates that will be automatically installed in the development environment container.

## 📋 Supported Certificate Formats

- **`.crt`** - Certificate files (PEM or DER encoded)
- **`.pem`** - PEM encoded certificates
- **`.cer`** - Certificate files (typically DER encoded)

## 📁 How to Add Certificates

### Method 1: Copy Existing Certificates
```bash
# Copy your corporate/custom certificates here
cp /path/to/your/certificates/*.crt certs/
cp /path/to/your/certificates/*.pem certs/
```

### Method 2: Export from Browser

**Chrome/Edge:**
1. Navigate to any internal corporate website
2. Click the padlock icon in address bar
3. Click "Certificate" → "Details" → "Export"
4. Save as "Base-64 encoded X.509 (.CRT)"
5. Copy the file to this `certs/` directory

**Firefox:**
1. Navigate to any internal corporate website
2. Click the padlock icon → "Connection secure" → "More information"
3. Click "View Certificate" → "Download" → "PEM (cert)"
4. Copy the file to this `certs/` directory

### Method 3: Export from Windows Certificate Store

**Windows Certificate Manager:**
1. Press `Win+R`, type `certmgr.msc`, press Enter
2. Navigate to "Trusted Root Certificate Authorities" → "Certificates"
3. Find your corporate certificate
4. Right-click → "All Tasks" → "Export"
5. Choose "Base-64 encoded X.509 (.CER)"
6. Save and copy to this `certs/` directory

**PowerShell Method:**
```powershell
# Export all trusted root certificates
Get-ChildItem -Path Cert:\LocalMachine\Root | ForEach-Object {
    $certPath = "certs\$($_.Thumbprint).crt"
    $certBytes = $_.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
    $certPem = [Convert]::ToBase64String($certBytes)
    $pemContent = "-----BEGIN CERTIFICATE-----`n$($certPem -replace '.{64}', "`$&`n")`n-----END CERTIFICATE-----"
    Set-Content -Path $certPath -Value $pemContent
}
```

### Method 4: Export from macOS Keychain

**Keychain Access:**
1. Open "Keychain Access" application
2. Select "System" keychain
3. Find your corporate certificate in "Certificates" category
4. Right-click → "Export [Certificate Name]"
5. Choose "Privacy Enhanced Mail (.pem)" format
6. Save and copy to this `certs/` directory

**Command Line:**
```bash
# Export system certificates
security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain > certs/macos-system-certs.pem

# Export user certificates
security find-certificate -a -p /Library/Keychains/System.keychain > certs/macos-user-certs.pem
```

### Method 5: Export from Linux Certificate Store

**Ubuntu/Debian:**
```bash
# Copy system certificates
sudo cp /etc/ssl/certs/*.crt certs/ 2>/dev/null || true
sudo cp /etc/ssl/certs/*.pem certs/ 2>/dev/null || true

# Copy custom certificates
sudo cp /usr/local/share/ca-certificates/*.crt certs/ 2>/dev/null || true
```

**CentOS/RHEL/Fedora:**
```bash
# Copy system certificates
sudo cp /etc/pki/ca-trust/source/anchors/*.crt certs/ 2>/dev/null || true
sudo cp /etc/ssl/certs/*.pem certs/ 2>/dev/null || true
```

## 🔧 How Certificates Are Used

### Automatic Installation
When the development environment starts, all certificates in this directory are:

1. **Copied** to `/usr/local/share/ca-certificates/` inside the container
2. **Installed** using `update-ca-certificates` command
3. **Made available** to all applications (Python, Node.js, Java, etc.)

### Applications That Use These Certificates

- **Python** - pip, requests, urllib3
- **Node.js** - npm, yarn, axios, fetch
- **Java** - Maven, Gradle, HTTPS connections
- **Git** - HTTPS repository access
- **curl/wget** - Command-line HTTP tools
- **AWS CLI** - HTTPS API connections

## 📝 Certificate Naming Guidelines

### Recommended Naming Convention
```
company-root-ca.crt          # Corporate root certificate
company-intermediate-ca.crt  # Intermediate certificates
github-enterprise.crt        # GitHub Enterprise certificate
artifactory.crt            # Package registry certificate
custom-service.crt          # Service-specific certificates
```

### Avoid These Naming Patterns
- Spaces in filenames: ❌ `company root ca.crt`
- Special characters: ❌ `ca@company.crt`
- Very long names: ❌ `very-long-certificate-name-that-is-hard-to-read.crt`

## 🔍 Verifying Certificates

### Check Certificate Contents
```bash
# View certificate details
openssl x509 -in certs/company-root-ca.crt -text -noout

# Check certificate validity
openssl x509 -in certs/company-root-ca.crt -noout -dates

# Verify certificate chain
openssl verify -CAfile certs/company-root-ca.crt certs/company-intermediate.crt
```

### Test Certificate Installation

**After starting the development environment:**
```bash
# Inside the container
./scripts/universal-dev-env.sh shell

# Test HTTPS connection to corporate services
curl -I https://artifactory.company.com
curl -I https://github.company.com

# Check if certificates are installed
ls -la /usr/local/share/ca-certificates/
```

## 🚨 Common Issues and Solutions

### Issue: Certificate not recognized
**Symptoms:** SSL verification errors, "certificate verify failed"

**Solutions:**
1. **Check file format**: Ensure certificates are in PEM format (text, not binary)
2. **Check file extension**: Use `.crt` or `.pem` extensions
3. **Verify certificate**: Use `openssl x509 -in cert.crt -text -noout`
4. **Check permissions**: Ensure files are readable (chmod 644)

### Issue: Wrong certificate format
**Symptoms:** "unable to load certificate" errors

**Solutions:**
```bash
# Convert DER to PEM format
openssl x509 -inform DER -in certificate.der -outform PEM -out certificate.crt

# Convert P7B to PEM format
openssl pkcs7 -inform DER -in certificate.p7b -print_certs -out certificate.crt

# Convert PFX to PEM format (requires password)
openssl pkcs12 -in certificate.pfx -out certificate.crt -nodes
```

### Issue: Certificate chain incomplete
**Symptoms:** "certificate chain verification failed"

**Solutions:**
1. **Get the complete chain**: Include root and intermediate certificates
2. **Proper order**: Root CA → Intermediate CA → End certificate
3. **Separate files**: Put each certificate in its own `.crt` file

### Issue: Corporate proxy blocking certificate validation
**Symptoms:** "connection timeout" or "proxy errors"

**Solutions:**
1. **Configure proxy** in `.universal-dev.env`:
   ```
   HTTP_PROXY=http://proxy.company.com:8080
   HTTPS_PROXY=http://proxy.company.com:8080
   NO_PROXY=localhost,127.0.0.1,.company.com
   ```
2. **Get proxy certificates**: Export proxy's SSL certificate
3. **Disable SSL verification temporarily** (not recommended):
   ```
   DISABLE_SSL_VERIFICATION=true
   ```

## 🛡️ Security Best Practices

### What TO Include
✅ **Corporate root CA certificates**  
✅ **Intermediate CA certificates**  
✅ **Service-specific certificates (GitHub Enterprise, Artifactory)**  
✅ **Proxy/firewall certificates**

### What NOT to Include
❌ **Private keys** (only public certificates)  
❌ **Client certificates with private keys**  
❌ **Expired certificates**  
❌ **Untrusted/self-signed certificates** (unless necessary)

### File Permissions
```bash
# Set secure permissions
chmod 644 certs/*.crt
chmod 644 certs/*.pem

# Verify no private keys are included
grep -r "PRIVATE KEY" certs/ && echo "WARNING: Private keys found!"
```

## 📞 Getting Help

### If certificates don't work:
1. **Verify format**: `openssl x509 -in cert.crt -text -noout`
2. **Check installation**: Start container and run `ls /usr/local/share/ca-certificates/`
3. **Test connection**: Try `curl -I https://your-corporate-site.com`
4. **Enable debug**: Start with `./scripts/universal-dev-env.sh start --debug`

### Contact your IT department for:
- Corporate root CA certificates
- Intermediate CA certificates  
- Proxy/firewall certificates
- Network configuration requirements

---

## 💡 Example Certificate Setup

```bash
# Example corporate setup
certs/
├── README.md                    # This file
├── corporate-root-ca.crt        # Main corporate CA
├── corporate-intermediate.crt   # Intermediate CA
├── github-enterprise.crt        # GitHub Enterprise Server
├── artifactory.crt             # Package registry
└── proxy-firewall.crt          # Corporate proxy certificate
```

**After adding certificates, rebuild the environment:**
```bash
./scripts/universal-dev-env.sh build --rebuild
```

Your certificates will be automatically installed and available to all applications! 🎉
$Out = "./certs"

Remove-Item -Path $Out -Recurse -Force

New-Item -ItemType Directory -Force -Path $Out | Out-Null

# PFX password (you’ll be prompted once and it’s reused)
$PfxPassword = Read-Host -AsSecureString "Enter a PFX password"

$root = New-SelfSignedCertificate `
  -Type Custom `
  -Subject "CN=Nexus Test Root CA" `
  -KeyAlgorithm RSA -KeyLength 2048 -HashAlgorithm sha256 `
  -KeyExportPolicy Exportable `
  -CertStoreLocation "Cert:\CurrentUser\My" `
  -NotAfter (Get-Date).AddYears(10) `
  -KeyUsage CertSign, CRLSign, DigitalSignature `
  -TextExtension @("2.5.29.19={critical}{text}ca=1&pathlength=0")

Export-Certificate -Cert $root -FilePath "$Out\Nexus-Test-Root-CA.cer" -Force

$dnsNames = @("api.nexus.net","portal.nexus.net","management.nexus.net")

foreach ($dns in $dnsNames) {
  $leaf = New-SelfSignedCertificate `
    -Type Custom `
    -DnsName $dns `
    -Subject "CN=$dns" `
    -KeyAlgorithm RSA -KeyLength 2048 -HashAlgorithm sha256 `
    -KeyExportPolicy Exportable `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -NotAfter (Get-Date).AddYears(2) `
    -Signer $root `
    -KeyUsage DigitalSignature, KeyEncipherment `
    -TextExtension @(
      "2.5.29.19={critical}{text}ca=0",                 # BasicConstraints: not a CA
      "2.5.29.37={text}1.3.6.1.5.5.7.3.1"               # EKU: Server Authentication
    )

  # Export a PFX for APIM, including the full chain, using TripleDES (APIM requirement)
  Export-PfxCertificate -Cert $leaf `
    -FilePath "$Out\$dns.pfx" `
    -Password $PfxPassword `
    -ChainOption BuildChain `
    -CryptoAlgorithmOption TripleDES_SHA1 `
    -Force | Out-Null
}

$PfxPath = "$Out\api.nexus.net.pfx"
$CertObj = Get-PfxCertificate -FilePath $PfxPath -Password $PfxPassword
Export-Certificate -Cert $CertObj -FilePath "$Out\\api.nexus.net.cer" -Force
& "C:\Program Files\Git\usr\bin\openssl.exe" x509 -in .\api.nexus.net.cer -noout -text

$PfxPath = "$Out\\management.nexus.net.pfx"; `
$CertObj = Get-PfxCertificate -FilePath $PfxPath -Password $PfxPassword; `
Export-Certificate -Cert $CertObj -FilePath "$Out\\management.nexus.net.cer" -Force; `
& "C:\Program Files\Git\usr\bin\openssl.exe" x509 -in .\management.nexus.net.cer -noout -text

$PfxPath = "$Out\\portal.nexus.net.pfx"; `
$CertObj = Get-PfxCertificate -FilePath $PfxPath -Password $PfxPassword; `
Export-Certificate -Cert $CertObj -FilePath "$Out\\portal.nexus.net.cer" -Force; `
& "C:\Program Files\Git\usr\bin\openssl.exe" x509 -in .\portal.nexus.net.cer -noout -text

# Use the official .NET Dev Container base image
FROM mcr.microsoft.com/devcontainers/dotnet

# Install PowerShell (latest stable)
RUN apt-get update && \
    apt-get install -y wget apt-transport-https software-properties-common && \
    wget -q "https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb" && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y powershell && \
    rm -f packages-microsoft-prod.deb

# (Optional) Set pwsh as default shell
CMD ["pwsh"]
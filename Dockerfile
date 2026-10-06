# escape=`
# Windows containers are required for MSVC, C++/CLI, and the kernel driver.
ARG BASE_IMAGE=mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2022
FROM ${BASE_IMAGE} AS buildtools

SHELL ["powershell.exe", "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]

ARG WDK_URL=https://go.microsoft.com/fwlink/?linkid=2335869
ARG NSIS_VERSION=3.11
COPY docker/Install-Dependencies.ps1 C:/docker/Install-Dependencies.ps1
RUN C:/docker/Install-Dependencies.ps1 -WdkUrl $env:WDK_URL -NsisVersion $env:NSIS_VERSION

ENV PATH="C:\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;C:\Program Files (x86)\NSIS;C:\Windows\system32;C:\Windows;C:\Windows\System32\WindowsPowerShell\v1.0"
COPY docker/entrypoint.cmd docker/Build.ps1 C:/docker/
WORKDIR C:/src
ENTRYPOINT ["C:\\docker\\entrypoint.cmd"]
CMD ["powershell.exe", "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "C:\\docker\\Build.ps1"]

# Keep dependency installation cached when project sources change.
FROM buildtools AS source
COPY . C:/src/

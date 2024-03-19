# escape=`
ARG BASETAG=ltsc2022
FROM mcr.microsoft.com/windows/server:${BASETAG} AS full

# Retrieve the DirectX runtime files required by the Unreal Engine, since even the full Windows base image does not include them
RUN curl -L "https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe" `
    --output %TEMP%\directx_redist.exe && `
	start /wait %TEMP%\directx_redist.exe /Q /T:%TEMP%\DirectX && `
	expand %TEMP%\DirectX\APR2007_xinput_x64.cab -F:xinput1_3.dll C:\Windows\System32\ && `
	expand %TEMP%\DirectX\Feb2010_X3DAudio_x64.cab -F:X3DAudio1_7.dll C:\Windows\System32\ && `
	expand %TEMP%\DirectX\Jun2010_D3DCompiler_43_x64.cab -F:D3DCompiler_43.dll C:\Windows\System32\ && `
	expand %TEMP%\DirectX\Jun2010_XAudio_x64.cab -F:XAudio2_7.dll C:\Windows\System32\ && `
	expand %TEMP%\DirectX\Jun2010_XAudio_x64.cab -F:XAPOFX1_5.dll C:\Windows\System32\

# Retrieve the DirectX shader compiler files needed for DirectX Raytracing (DXR)
RUN cd %TEMP% && curl -L "https://github.com/microsoft/DirectXShaderCompiler/releases/download/v1.7.2308/dxc_2023_08_14.zip" `
	--output dxc.zip && `
	powershell -Command "Expand-Archive -Path \"$env:TEMP\dxc.zip\" -DestinationPath $env:TEMP\dxc" && `
	xcopy /y %TEMP%\dxc\bin\x64\dxcompiler.dll C:\Windows\System32\ && `
	xcopy /y %TEMP%\dxc\bin\x64\dxil.dll C:\Windows\System32\

# Install the Visual C++ runtime files and Git using Chocolatey
RUN powershell -NoProfile -ExecutionPolicy Bypass -Command `
   "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"
RUN choco install -y vcredist-all git

# Clone Signalling Server from git repository and run init setup
RUN git clone --branch UE5.3 https://github.com/EpicGamesExt/PixelStreamingInfrastructure.git
RUN powershell -Command "Start-Process `
	-FilePath "C:\PixelStreamingInfrastructure\SignallingWebServer\platform_scripts\cmd\setup.bat" `
	-Wait -NoNewWindow"

# Copy our Unreal Engine application into the container image here
# (This assumes we have a packaged project called "MyProject" with a `-Cmd.exe` suffixed
#  version as per the blog post "Offscreen rendering in Windows containers")
RUN mkdir C:\projects\ThaiVanLung\Packaged\
COPY \v6-TestPixelStreaming\ C:\projects\ThaiVanLung\Packaged\

# Copy the helper script (and accompanying PowerShell script) into the container image
COPY entrypoint.cmd C:\entrypoint.cmd
COPY enable-graphics-apis.ps1 C:\enable-graphics-apis.ps1

# Set our Enable GPU APIs scripts as the container's entrypoint
ENTRYPOINT ["cmd.exe", "/S", "/K", "C:\\entrypoint.cmd", "powershell.exe"]

#docker build . -f Dockerfile.mcr -t duochh/thaivanlung-pixel-streaming:ltsc2022
#docker network create --driver nat --subnet=172.20.0.0/16 devnetwork
#docker inspect network devnetwork
#docker run -it --isolation process --device class/5B45201D-F2F2-4F3B-85BB-30FF1F953599 --net devnetwork --ip 172.20.0.4 --name thaivanlung duochh/thaivanlung-pixel-streaming:ltsc2022
#docker push duochh/thaivanlung-pixel-streaming:ltsc2022
#docker cp de03f339a59e:C:\projects\ThaiVanLung\Packaged\Windows\THAIVANLUNG\Saved\Logs C:\Users\PC-071\Downloads
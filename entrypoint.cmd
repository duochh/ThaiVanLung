@rem Source code from: https://unrealcontainers.com/blog/enabling-vendor-specific-graphics-apis-in-windows-containers/

@rem @echo off

@rem Enable vendor-specific graphics APIs if the container is running with GPU acceleration
powershell -ExecutionPolicy Bypass -File "%~dp0.\enable-graphics-apis.ps1"

@rem Run Pixel Streaming package
powershell "%~dp0.\projects\ThaiVanLung\Packaged\Windows\THAIVANLUNG\Binaries\Win64\THAIVANLUNG.exe -PixelStreamingIP=127.0.0.1 -PixelStreamingPort=8888 -PixelStreamingUrl=ws://localhost:8888 -AllowPixelStreamingCommands -RenderOffScreen -StdOut -FullStdOutLogOutput"

@rem Start Pixel Streaming Signalling server
powershell "%~dp0.\PixelStreamingInfrastructure\SignallingWebServer\platform_scripts\cmd\Start_SignallingServer.ps1 -Wait -NoNewWindow"

@rem Run the entrypoint command specified via our command-line parameters
%*
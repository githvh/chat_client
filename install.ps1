# Check and install Python
function Check-Python {
    try {
        $pythonVersion = python --version
        Write-Host "Python is already installed: $pythonVersion"
        return $true
    }
    catch {
        Write-Host "Python not found. Starting installation..."
        return $false
    }
}

function Install-Python {
    Write-Host "Downloading Python..."
    $pythonUrl = "https://www.python.org/ftp/python/3.9.7/python-3.9.7-amd64.exe"
    $installerPath = "$env:TEMP\python_installer.exe"
    
    try {
        Invoke-WebRequest -Uri $pythonUrl -OutFile $installerPath
        Write-Host "Installing Python..."
        Start-Process -FilePath $installerPath -ArgumentList "/quiet", "InstallAllUsers=1", "PrependPath=1" -Wait
        Remove-Item $installerPath
        Write-Host "Python installed successfully!"
        return $true
    }
    catch {
        Write-Host "Error installing Python: $_"
        return $false
    }
}

# Create client script
function Create-ClientScript {
    $clientCode = @'
import socket
import sys
import os

def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

def print_header():
    print("=" * 50)
    print("             SIMPLE AI CHAT CLIENT")
    print("=" * 50)
    print("Enter 'exit' to quit")
    print("Enter 'clear' to clear screen")
    print("=" * 50)
    print()

def start_client():
    clear_screen()
    print_header()
    
    # Create client socket (initially empty)
    client = None

    while True:
        try:
            # Request server IP address
            server_ip = input("Enter server IP address (for IPv6 use square brackets, e.g., [::1]): ")
            if not server_ip:
                print("IP address cannot be empty!")
                continue
                
            port = 5000
            
            # Determine if the IP address is IPv6 or IPv4
            if ':' in server_ip:
                # IPv6 address
                addr_family = socket.AF_INET6
                # Remove square brackets if present, for correct processing
                if server_ip.startswith('[') and server_ip.endswith(']'):
                    server_ip = server_ip[1:-1]
                # For IPv6, connect requires a 4-element tuple: (host, port, flowinfo, scopeid)
                server_address = (server_ip, port, 0, 0) 
            else:
                # IPv4 address
                addr_family = socket.AF_INET
                server_address = (server_ip, port)

            # Create the client socket of the appropriate type
            client = socket.socket(addr_family, socket.SOCK_STREAM)

            # Connect to the server
            print(f"Connecting to {server_ip}...")
            client.connect(server_address)
            print("Connected to the server!")
            print()
            
            while True:
                # Get message from user
                message = input("You: ")
                
                if message.lower() == 'exit':
                    return
                elif message.lower() == 'clear':
                    clear_screen()
                    print_header()
                    continue
                
                # Send message to server
                client.send(message.encode('utf-8'))
                
                # Get response from server
                response = client.recv(1024).decode('utf-8')
                print(f"AI: {response}")
                print()
                
        except ConnectionRefusedError:
            print("Could not connect to the server.")
            print("Check:")
            print("1. Correct IP address")
            print("2. If the server is running")
            print("3. If necessary ports are open")
            print()
            retry = input("Do you want to try again? (y/n): ")
            if retry.lower() != 'y':
                return
            # Recreate the client socket to try again with a new address
            if client:
                client.close() # Close the old socket before creating a new one
            client = None # Reset socket so it's created anew on next iteration
            
        except Exception as e:
            print(f"Error: {e}")
            print()
            retry = input("Do you want to try again? (y/n): ")
            if retry.lower() != 'y':
                return
            # Recreate the client socket to try again with a new address
            if client:
                client.close() # Close the old socket before creating a new one
            client = None # Reset socket so it's created anew on next iteration
            
        finally:
            # Close the socket only if it was successfully created
            if client:
                try:
                    client.close()
                except:
                    pass

if __name__ == "__main__":
    try:
        start_client()
    except KeyboardInterrupt:
        print("\nProgram terminated")
    except Exception as e:
        print(f"\nUnexpected error: {e}")
    finally:
        print("\nGoodbye!")
        input("Press Enter to exit...")
'@

    $clientPath = "$env:USERPROFILE\AI_Chat\simple_client.py"
    New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\AI_Chat" | Out-Null
    Set-Content -Path $clientPath -Value $clientCode
    return $clientPath
}

# Create bat file for launching
function Create-Launcher {
    $launcherCode = @'
@echo off
echo Launching AI chat client...
python "%~dp0simple_client.py"
pause
'@

    $launcherPath = "$env:USERPROFILE\AI_Chat\start_chat.bat"
    Set-Content -Path $launcherPath -Value $launcherCode
    return $launcherPath
}

# Create desktop shortcut
function Create-Shortcut {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\AI Chat.lnk")
    $Shortcut.TargetPath = "$env:USERPROFILE\AI_Chat\start_chat.bat"
    $Shortcut.WorkingDirectory = "$env:USERPROFILE\AI_Chat"
    $Shortcut.Save()
}

# Main installation process
Write-Host "=== AI Chat Client Installation ==="
Write-Host ""

if (-not (Check-Python)) {
    if (-not (Install-Python)) {
        Write-Host "Error: Could not install Python. Installation aborted."
        exit
    }
}

Write-Host "Creating client script..."
$clientPath = Create-ClientScript

Write-Host "Creating launch file..."
$launcherPath = Create-Launcher

Write-Host "Creating desktop shortcut..."
Create-Shortcut

Write-Host ""
Write-Host "=== Installation Complete! ==="
Write-Host "Client installed to: $env:USERPROFILE\AI_Chat"
Write-Host "Shortcut created on desktop"
Write-Host ""
Write-Host "To launch the client:"
Write-Host "1. Double-click the 'AI Chat' shortcut on the desktop"
Write-Host "2. Or run the file: $launcherPath"
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

$ps3Installed = $false
$PSVersion,$CLRVersion = powershell -NoProfile -NonInteractive -Command { $PSVersionTable.PSVersion ; $PSVersionTable.CLRVersion }

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
}

function Start-Test
{
    $ps3Installed = Test-Path -Path HKLM:\SOFTWARE\Microsoft\PowerShell\3
}

function Test-ShouldInvokePowerShell
{
    $command = {
        param(
            $Argument
        )
        
        $Argument
    }
    
    $result = Invoke-PowerShell -ScriptBlock $command -Args 'Hello World!'
    Assert-Equal 'Hello world!' $result
}

function Test-ShouldInvokePowerShellx86
{
    $command = {
        $env:PROCESSOR_ARCHITECTURE
    }
    
    $result = Invoke-PowerShell -ScriptBlock $command -x86
    Assert-Equal 'x86' $result
}

if( Test-Path -Path HKLM:\SOFTWARE\Microsoft\PowerShell\3 )
{
    if( $Host.Name -eq 'Windows PowerShell ISE Host' )
    {
        function Test-ShouldNotRunScriptBlockUnderV2ISEClr2
        {
            $command = {
                $PSVersionTable.CLRVersion
            }
    
            $error.Clear()
            $result = Invoke-PowerShell -ScriptBlock $command -Runtime v2.0 -ErrorAction SilentlyContinue
            Assert-Equal 1 $error.Count
            Assert-Null $result
            Assert-Null ([Environment]::GetEnvironmentVariable('COMPLUS_ApplicationMigrationRuntimeActivationConfigPath'))
        }
    }
    else
    {
        function Test-ShouldRunScriptBlockUnderV3ConsoleClr2
        {
            Assert-True (Test-DotNet -V2) '.NET v2 isn''t installed'
            $command = {
                $PSVersionTable.CLRVersion
            }
    
            $error.Clear()
            $result = Invoke-PowerShell -ScriptBlock $command -Runtime v2.0 
            Assert-Equal 0 $error.Count
            Assert-NotNull $result
            Assert-Equal 2 $result.Major
            Assert-Null ([Environment]::GetEnvironmentVariable('COMPLUS_ApplicationMigrationRuntimeActivationConfigPath'))
        }
    }
}
else
{
    function Test-ShouldRunScriptBlockUnderV2ConsoleClr2
    {
        $command = {
            $PSVersionTable.CLRVersion
        }
    
        $result = Invoke-PowerShell -ScriptBlock $command
        $expectedClr = 2
        Assert-Equal 2 $result.Major
        Assert-Null ([Environment]::GetEnvironmentVariable('COMPLUS_ApplicationMigrationRuntimeActivationConfigPath'))
    }
}

function Test-ShouldRunPowerShellUnderCLR4
{
    $command = {
        $PSVersionTable.CLRVersion
    }
    
    $result = Invoke-PowerShell -Command $command -Runtime v4.0
    Assert-Equal 4 $result.Major
    Assert-Null ([Environment]::GetEnvironmentVariable('COMPLUS_ApplicationMigrationRuntimeActivationConfigPath'))
}

function Test-ShouldRunx64PowerShellFromx86PowerShell
{
    if( (Test-OsIs64Bit) -and (Test-PowerShellIs32Bit) )
    {
        $error.Clear()
        $result = Invoke-PowerShell -ScriptBlock { $env:PROCESSOR_ARCHITECTURE } -ErrorAction SilentlyContinue
        Assert-Equal 0 $error.Count
        Assert-Equal 'AMD64' $result
    }
    else
    {
        Write-Warning "This test is only valid if running 32-bit PowerShell on a 64-bit operating system."
    }
}


function Test-ShouldRunx86PowerShellFromx86PowerShell
{
    if( (Test-OsIs64Bit) -and (Test-PowerShellIs32Bit) )
    {
        $error.Clear()
        $result = Invoke-PowerShell -ScriptBlock { $env:ProgramFiles } -x86
        Assert-Equal 0 $error.Count
        Assert-True ($result -like '*Program Files (x86)*')
    }
    else
    {
        Write-Warning "This test is only valid if running 32-bit PowerShell on a 64-bit operating system."
    }
}

function Test-ShouldRunScript
{
    $result = Invoke-PowerShell -FilePath (Join-Path $TestDir Get-PSVersionTable.ps1) `
                                -OutputFormat XML `
                                -ExecutionPolicy RemoteSigned `
                                -ErrorAction SilentlyContinue 2> $null
    Assert-Equal 3 $result.Length
    Assert-Equal '' $result[0]
    Assert-NotNull $result[1]
    Assert-Equal $PSVersion $result[1].PSVersion
    Assert-Equal $CLRVersion $result[1].CLRVersion
    Assert-NotNull $result[2]
    $architecture = 'AMD64'
    if( Test-OSIs32Bit )
    {
        $architecture = 'x86'
    }
    Assert-Equal $architecture $result[2]
}

function Test-ShouldRunScriptWithArguments
{
    $result = Invoke-PowerShell -FilePath (Join-Path $TestDir Get-PSVersionTable.ps1) `
                                -OutputFormat XML `
                                -ArgumentList '-Message',"'Hello World'" `
                                -ExecutionPolicy RemoteSigned `
                                -ErrorAction SilentlyContinue 2> $null
    Assert-Equal 3 $result.Length
    Assert-Equal "'Hello World'" $result[0]
    Assert-NotNull $result[1]
    Assert-Equal $PSVersion $result[1].PSVersion
    Assert-Equal $CLRVersion $result[1].CLRVersion
}

function Test-ShouldRunScriptUnderPowerShell2
{
    $result = Invoke-PowerShell -FilePath (Join-Path $TestDir Get-PSVersionTable.ps1) `
                                -OutputFormat XML `
                                -x86 `
                                -ExecutionPolicy RemoteSigned `
                                -ErrorAction SilentlyContinue 2> $null
    Assert-Equal 'x86' $result[2]
}

function Test-ShouldRunUnderClr4
{
    $result = Invoke-PowerShell -FilePath (Join-Path $TestDir Get-PSVersionTable.ps1) `
                                -OutputFormat XML `
                                -Runtime 'v4.0' `
                                -ExecutionPolicy RemoteSigned `
                                -ErrorAction SilentlyContinue 2> $null
    Assert-Like $result[1].CLRVersion '4.0.*' 
}

function Test-ShouldRunUnderClr2
{
    Assert-True (Test-DotNet -V2) '.NET v2 is not installed'
    $result = Invoke-PowerShell -FilePath (Join-Path $TestDir Get-PSVersionTable.ps1) `
                                -OutputFormat XML `
                                -Runtime 'v2.0' `
                                -ExecutionPolicy RemoteSigned `
                                -ErrorAction SilentlyContinue 2> $null
    Assert-NotNull $result
    Assert-Like $result[1].CLRVersion '2.0.*'
}

function Test-ShouldUseExecutionPolicy
{
    $Error.Clear()
    $result = Invoke-PowerShell -FilePath (Join-Path $TestDir Get-PsVersionTable.ps1) `
                                -ExecutionPolicy Restricted `
                                -ErrorAction SilentlyContinue 2> $null
    #Assert-LastProcessFailed

    if( $result )
    {
        Assert-Like $result[0] '*disabled*'
    }

    # For some reason, when run under CCNet, $Error doesn't get populated.
    if( $Error )
    {
        Assert-ContainsLike $Error '*disabled*'
    }
}

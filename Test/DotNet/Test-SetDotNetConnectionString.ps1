# Copyright 2012 Aaron Jensen
# 
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
$connectionStringName = "TEST_CONNECTION_STRING_NAME"
$connectionStringValue = "TEST_CONNECTION_STRING_VALUE"
$connectionStringNewValue = "TEST_CONNECTION_STRING_NEW_VALUE"

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon) -Force
    Remove-ConnectionStrings    
}

function TearDown
{
    Remove-ConnectionStrings
    Remove-Module Carbon
}

function Remove-ConnectionStrings
{
    $command = {
        param(
            $Name
        )
        
        Add-Type -AssemblyName System.Configuration
        
        $config = [Configuration.ConfigurationManager]::OpenMachineConfiguration()
        $connectionStrings = $config.ConnectionStrings.ConnectionStrings
        if( $connectionStrings[$Name] )
        {
            $connectionStrings.Remove( $Name )
            $config.Save()
        }
    }
    
    Invoke-PowerShell -Command $command -Args $connectionStringName -x86
    Invoke-PowerShell -Command $command -Args $connectionStringName 
    Invoke-PowerShell -Command $command -Args $connectionStringName -x86 -Runtime v4.0
    Invoke-PowerShell -Command $command -Args $connectionStringName -Runtime v4.0
}

function Test-ShouldUpdateDotNet2x86MachineConfig
{
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework -Clr2
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework -Clr2
}

function Test-ShouldUpdateDotNet2x64MachineConfig
{
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework64 -Clr2
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework64 -Clr2
}

function Test-ShouldUpdateDotNet4x86MachineConfig
{
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework -Clr4
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework -Clr4
}

function Test-ShouldUpdateDotNet4x64MachineConfig
{
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework64 -Clr4
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework64 -Clr4
}

function Test-ShouldUpdateConnectionString
{
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework -Clr2
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringNewValue -Framework -Clr2
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringNewValue -Framework -Clr2 
}

function Test-ShouldRequireAFrameworkFlag
{
    $error.Clear()
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Clr2 -ErrorACtion SilentlyContinue
    Assert-Equal 1 $error.Count
    Assert-Like $error[0].Exception 'You must supply either or both of the Framework and Framework64 switches.'
}

function Test-ShouldRequireAClrFlag
{
    $error.Clear()
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework -ErrorACtion SilentlyContinue
    Assert-Equal 1 $error.Count
    Assert-Like $error[0].Exception 'You must supply either or both of the Clr2 and Clr4 switches.'    
}

function Assert-ConnectionString($Name, $value, [Switch]$Framework, [Switch]$Framework64, [Switch]$Clr2, [Switch]$Clr4)
{
    $command = {
        param(
            $Name
        )
        
        Add-Type -AssemblyName System.Configuration
        
        $config = [Configuration.ConfigurationManager]::OpenMachineConfiguration()
        
        $connectionStrings = $config.ConnectionStrings.ConnectionStrings
        
        if( $connectionStrings[$Name] )
        {
            $connectionStrings[$Name].ConnectionString
        }
        else
        {
            $null
        }
    }
    
    $runtimes = @()
    if( $Clr2 )
    {
        $runtimes += 'v2.0'
    }
    if( $Clr4 )
    {
        $runtimes += 'v4.0'
    }
    
    if( $runtimes.Length -eq 0 )
    {
        throw "Must supply either or both the Clr2 and Clr2 switches."
    }
    
    $runtimes | ForEach-Object {
        $params = @{
            Command = $command
            Args = $Name
            Runtime = $_
        }

        if( $Framework64 )
        {
            $actualValue = Invoke-PowerShell @params
            Assert-Equal $Value $actualValue
        }
        
        if( $Framework )
        {
            $actualValue = Invoke-PowerShell @params -x86
            Assert-Equal $Value $actualValue
        }
    }
}

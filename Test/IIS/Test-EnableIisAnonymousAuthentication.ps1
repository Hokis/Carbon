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

$siteName = 'Anonymous Authentication'
$sitePort = 4387
$webConfigPath = Join-Path $TestDir web.config

function Setup
{
    & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)
    Remove-IisWebsite $siteName
    Install-IisWebsite -Name $siteName -Path $TestDir -Bindings "http://*:$sitePort"
    if( Test-Path $webConfigPath -PathType Leaf )
    {
        Remove-Item $webConfigPath
    }
}

function TearDown
{
    Remove-IisWebsite $siteName
    Remove-Module Carbon
}

function Test-ShouldEnableAnonymousAuthentication
{
    Enable-IisAnonymousAuthentication -SiteName $siteName
    Assert-AnonymousAuthentication -Enabled 'true'
    Assert-FileDoesNotExist $webConfigPath 
}

function Test-ShouldEnableAnonymousAuthenticationOnSubFolders
{
    Enable-IisAnonymousAuthentication -SiteName $siteName -Path SubFolder
    Assert-AnonymousAuthentication -Path "$siteName/SubFolder" -Enabled 'true'
}

function Test-ShouldSupportWhatIf
{
    Enable-IisAnonymousAuthentication $siteName 
    Assert-AnonymousAuthentication -Enabled 'true'
}

function Assert-AnonymousAuthentication($Path = $siteName, $Enabled)
{
    $authSettings = [xml] (Invoke-AppCmd list config $Path '-section:anonymousAuthentication')
    $authNode = $authSettings['system.webServer'].security.authentication.anonymousAuthentication
    Assert-Equal $Enabled $authNode.enabled
    Assert-Equal '' $authNode.username
}
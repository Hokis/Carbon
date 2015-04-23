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

function Install-Group
{
    <#
    .SYNOPSIS
    Creates a new local group, or updates the settings for an existing group.

    .DESCRIPTION
    Creates a new group with a description and default set of members.  If a group with the same name already exists, it updates the group's description and adds the given members to it.

    .EXAMPLE
    Install-Group -Name TIEFighters -Description 'Users allowed to be TIE fighter pilots.' -Members EMPIRE\Pilots,EMPIRE\DarthVader

    If the TIE fighters group doesn't exist, it is created with the given description and default members.  If it already exists, its description is updated and the given members are added to it.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the group.
        $Name,
        
        [string]
        # A description of the group.
        $Description = '',
        
        [Alias('Members')]
        [string[]]
        # Members of the group.
        $Member = @(),

        [Switch]
        # Return the group object.
        $PassThru
    )
    
    Set-StrictMode -Version 'Latest'

    $ctx = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' ([DirectoryServices.AccountManagement.ContextType]::Machine)
    $group = [DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity( $ctx, $Name )
    $operation = 'update'
    if( -not $group )
    {
        $operation = 'create'
        $group = New-Object 'DirectoryServices.AccountManagement.GroupPrincipal' $ctx
    }

    $group.Name = $Name
    $group.Description = $Description

    if( $PSCmdlet.ShouldProcess( $Name, "$operation local group" ) )
    {
        $group.Save()
        if( $Member )
        {
            Add-GroupMember -Name $Name -Member $Member
        }
    }
    
    if( $PassThru )
    {
        return $group
    }
}

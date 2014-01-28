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

$username = 'CarbonInstallUser'
$password = [Guid]::NewGuid().ToString().Substring(0,15)

function Start-Test
{
    Import-Module (Join-Path $TestDir ..\..\Carbon) -Force
    Remove-TestUser
}

function Stop-Test
{
    Remove-TestUser
    Remove-Module Carbon
}

function Remove-TestUser
{
    Uninstall-User -Username $username
}

function Test-ShouldCreateNewUser
{
    $fullName = 'Carbon Install User'
    $description = "Test user for testing the Carbon Install-User function."
    Install-User -Username $username -Password $password -Description $description -FullName $fullName
    Assert-True (Test-User -Username $username)
    $user = Get-WmiLocalUserAccount -Username $Username
    Assert-NotNull $user
    Assert-Equal $description $user.Description
    Assert-False $user.PasswordExpires 
    Assert-Equal $fullName $user.FullName
    Assert-Credential -Password $password
}

function Test-ShouldUpdateExistingUsersProperties
{
    $fullName = 'Carbon Install User'
    Install-User -Username $username -Password $password -Description "Original description" -FullName $fullName
    $originalUser = Get-WmiLocalUserAccount -Username $username
    Assert-NotNull $originalUser
    
    $newFullName = 'New {0}' -f $fullName
    $newDescription = "New description"
    $newPassword = [Guid]::NewGuid().ToString().Substring(0,14)
    Install-User -Username $username `
                 -Password $newPassword `
                 -Description $newDescription `
                 -FullName $newFullName `
                 -PasswordExpires 

    $newUser = Get-WmiLocalUserAccount -Username $username
    Assert-NotNull $newUser
    Assert-Equal $originalUser.SID $newUser.SID
    Assert-Equal $newDescription $newUser.Description
    Assert-Equal $newFullName $newUser.FullName
    Assert-True $newUser.PasswordExpires
    Assert-Credential -Password $newPassword
}

function Test-ShouldAllowOptionalFullName
{
    $fullName = 'Carbon Install User'
    $description = "Test user for testing the Carbon Install-User function."
    Install-User -Username $username -Password $password -Description $description
    $user = Get-WmiLocalUserAccount -Username $Username
    Assert-Empty $user.FullName
}

function Test-ShouldSupportWhatIf
{
    Install-User -Username $username -Password $password -WhatIf
    $user = Get-WmiLocalUserAccount -Username $username
    Assert-Null $user
}

function Assert-Credential
{
    param(
        $Password
    )
    $ctx = [DirectoryServices.AccountManagement.ContextType]::Machine
    $px = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' $ctx,$env:COMPUTERNAME
    Assert-True ($px.ValidateCredentials( $username, $password ))
}

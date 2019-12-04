[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $CmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\Office365.psm1" `
            -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
        -ChildPath "..\UnitTestHelper.psm1" `
        -Resolve)

$Global:DscHelper = New-O365DscUnitTestHelper -StubModule $CmdletModule `
    -DscResource "SCFilePlanPropertySubCategory"
Describe -Name $Global:DscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:DscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:DscHelper.InitializeScript -NoNewScope

        $secpasswd = ConvertTo-SecureString "test@password1" -AsPlainText -Force
        $GlobalAdminAccount = New-Object System.Management.Automation.PSCredential ("tenantadmin", $secpasswd)

        Mock -CommandName Test-MSCloudLogin -MockWith {

        }

        Mock -CommandName Remove-FilePlanPropertySubCategory -MockWith {
            return @{

            }
        }

        Mock -CommandName New-FilePlanPropertySubCategory -MockWith {
            return @{

            }
        }

        # Test contexts
        Context -Name "Sub-Category doesn't already exist" -Fixture {
            $testParams = @{
                Name               = "Demo Sub-Category"
                Category           = "Parent"
                GlobalAdminAccount = $GlobalAdminAccount
                Ensure             = "Present"
            }

            Mock -CommandName Get-FilePlanPropertyCategory -MockWith {
                return @(@{
                        DisplayName = "Parent"
                        Id          = "11111-22222-33333-44444-55555"
                    })
            }

            Mock -CommandName Get-FilePlanPropertySubCategory -MockWith {
                return $null
            }

            It 'Should return false from the Test method' {
                Test-TargetResource @testParams | Should Be $false
            }

            It 'Should return Absent from the Get method' {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should call the Set method" {
                Set-TargetResource @testParams
            }
        }

        Context -Name "Category already exists" -Fixture {
            $testParams = @{
                Name               = "Demo Sub-Category"
                Category           = "Parent"
                GlobalAdminAccount = $GlobalAdminAccount
                Ensure             = "Present"
            }

            Mock -CommandName Get-FilePlanPropertyCategory -MockWith {
                return @(@{
                        DisplayName = "Parent"
                        Id          = "CN=11111-22222-33333-44444-55555"
                    })
            }

            Mock -CommandName Get-FilePlanPropertySubCategory -MockWith {
                return @(@{
                        DisplayName = "Demo Sub-Category"
                        ParentId    = "11111-22222-33333-44444-55555"
                    })
            }

            It 'Should return true from the Test method' {
                Test-TargetResource @testParams | Should Be $true
            }

            It 'Should do nothing from the Set method' {
                Set-TargetResource @testParams
            }

            It 'Should return Present from the Get method' {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }
        }

        Context -Name "Category should not exist" -Fixture {
            $testParams = @{
                Name               = "Demo Sub-Category"
                Category           = "Parent"
                GlobalAdminAccount = $GlobalAdminAccount
                Ensure             = "Absent"
            }

            Mock -CommandName Get-FilePlanPropertyCategory -MockWith {
                return @(@{
                        DisplayName = "Parent"
                        Id          = "11111-22222-33333-44444-55555"
                    })
            }

            Mock -CommandName Get-FilePlanPropertySubCategory -MockWith {
                return @(@{
                        DisplayName = "Demo Sub-Category"
                        ParentId    = "11111-22222-33333-44444-55555"
                    })
            }

            It 'Should return False from the Test method' {
                Test-TargetResource @testParams | Should Be $False
            }

            It 'Should delete from the Set method' {
                Set-TargetResource @testParams
            }

            It 'Should return Present from the Get method' {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }
        }

        Context -Name "ReverseDSC Tests" -Fixture {
            $testParams = @{
                GlobalAdminAccount = $GlobalAdminAccount
            }

            Mock -CommandName Get-FilePlanPropertyCategory -MockWith {
                return @(@{
                        DisplayName = "Parent"
                        Id          = "11111-22222-33333-44444-55555"
                    })
            }

            Mock -CommandName Get-FilePlanPropertySubCategory -MockWith {
                return @(@{
                        DisplayName = "Demo Sub-Category"
                        ParentId    = "11111-22222-33333-44444-55555"
                    })
            }

            It "Should Reverse Engineer resource from the Export method" {
                Export-TargetResource @testParams
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:DscHelper.CleanupScript -NoNewScope

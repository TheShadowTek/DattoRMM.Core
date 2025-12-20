# Datto-RMM Pester Tests

This directory contains Pester tests for the Datto-RMM PowerShell module.

## Prerequisites

Install Pester v5+ if not already installed:

```powershell
Install-Module -Name Pester -MinimumVersion 5.0 -Force -SkipPublisherCheck
```

## Running Tests

### Run all tests
```powershell
Invoke-Pester
```

### Run specific test file
```powershell
Invoke-Pester -Path .\Get-RMMVariable.Tests.ps1
```

### Run tests with detailed output
```powershell
Invoke-Pester -Output Detailed
```

### Run tests and generate code coverage report
```powershell
$Config = New-PesterConfiguration
$Config.CodeCoverage.Enabled = $true
$Config.CodeCoverage.Path = '..\Public\*.ps1', '..\Private\*.ps1'
$Config.Output.Verbosity = 'Detailed'
Invoke-Pester -Configuration $Config
```

## Test Structure

Each test file follows this structure:

- **BeforeAll**: Module import and mock setup
- **Describe**: Function being tested
- **Context**: Specific scenario or feature
- **It**: Individual test assertion

## Key Testing Patterns

### Mocking API calls
```powershell
Mock Invoke-APIMethod {
    [PSCustomObject]@{id = 1; name = 'Test'}
} -ParameterFilter {$Path -eq 'account/variables'}
```

### Testing parameter sets
```powershell
It 'Has correct parameter set' {
    $Command = Get-Command Get-RMMVariable
    $Command.ParameterSets.Name | Should -Contain 'GlobalAll'
}
```

### Testing pipeline input
```powershell
It 'Accepts objects from pipeline' {
    $Result = $MockObject | Get-RMMVariable
    $Result | Should -Not -BeNullOrEmpty
}
```

### Testing object types
```powershell
It 'Returns correct object type' {
    $Result = Get-RMMVariable
    $Result[0] | Should -BeOfType [DRMMVariable]
}
```

## Writing New Tests

When adding tests for new functions:

1. Create `FunctionName.Tests.ps1` in this directory
2. Follow the existing test structure
3. Mock all external API calls
4. Test all parameter sets
5. Test pipeline input scenarios
6. Test error conditions
7. Verify object types and properties

## CI/CD Integration

These tests can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions step
- name: Run Pester Tests
  run: |
    Invoke-Pester -CI
```

The `-CI` switch produces output suitable for CI systems.

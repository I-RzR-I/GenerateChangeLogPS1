#region [Get comment/id/hash]

<#
	.SYNOPSIS
		Get comment from current commit
	
	.DESCRIPTION
		Get comment added by user on commit changes
	
	.PARAMETER commitItem
		A description of the commitItem parameter.
	
	.EXAMPLE
		PS C:\> Get-CommitMessage
	
	.NOTES
		
#>
function Get-CommitMessage
{
	[OutputType([string])]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$commitItem
	)
	
	return $commitItem.Substring(43, $commitItem.Length - 43);
}

<#
	.SYNOPSIS
		Get commit hash
	
	.DESCRIPTION
		Get commit hash assigned to user on add new changes
	
	.PARAMETER commitItem
		A description of the commitItem parameter.
	
	.EXAMPLE
		PS C:\> Get-CommitHash
	
	.NOTES
		
#>
function Get-CommitHash
{
	[OutputType([string])]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$commitItem
	)
	
	return $commitItem.Substring(3, 7);
}

<#
	.SYNOPSIS
		Get commit identifier
	
	.DESCRIPTION
		Get current commit identifier generated when user add new changes
	
	.PARAMETER commitItem
		A description of the commitItem parameter.
	
	.EXAMPLE
		PS C:\> Get-CommitId
	
	.NOTES
		
#>
function Get-CommitId
{
	[OutputType([string])]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$commitItem
	)
	
	return $commitItem.Substring(3, 40);
}

#endregion

#region [Change log]

<#
	.SYNOPSIS
		Add/Append cahnge log
	
	.DESCRIPTION
		Append to current change log file new modification
	
	.PARAMETER commitHash
		Commit hash code.
	
	.PARAMETER commitComment
		Commit comment.
	
	.PARAMETER changeType
		0 => Add empty row;
		1 => Add Version;
		2 => Add new change row.
	
	.EXAMPLE
		PS C:\> Add-ChangeLog
	
	.NOTES
		
#>
function Add-ChangeLog
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 0)]
		[int16]$changeType,
		[Parameter(Mandatory = $false, Position = 1)]
		[string]$commitHash,
		[Parameter(Mandatory = $false, Position = 2)]
		[string]$commitComment,
		[Parameter(Mandatory = $false, Position = 3)]
		[string]$version
	)
	
	$changeLogPath = "..\CHANGELOG.md";
	
	If ($changeType -eq 0)
	{ @("") + (Get-Content $changeLogPath) | Set-Content $changeLogPath; }
	ElseIf ($changeType -eq 1)
	{ @("# v$version") + (Get-Content $changeLogPath) | Set-Content $changeLogPath; }
	Else
	{
		$commitRecord = "* [$commitHash] -> " + $commitComment;
		
		@($commitRecord) + (Get-Content $changeLogPath) | Set-Content $changeLogPath;
	}
}

#endregion

#region [Main Execution]

$brachToCheck = "develop";
$currentBranch = git branch --show-current;

# Add empty row before all commits
Add-ChangeLog -changeType 0;

# Add new commit log
$brachDiffCommits = git cherry -v $brachToCheck $currentBranch;
foreach ($commitItem in $brachDiffCommits)
{
	$commitHash = Get-CommitHash -commitItem $commitItem;
	$commitComment = Get-CommitMessage -commitItem $commitItem;
	
	Add-ChangeLog -changeType 2 -commitHash $commitHash -commitComment $commitComment;
}

# Generate new application version
$appVersion = .\generate-new-version.ps1;
Add-ChangeLog -changeType 1 -version $appVersion;

#endregion
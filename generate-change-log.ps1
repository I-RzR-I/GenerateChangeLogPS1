#How to use:
# .\generate-change-log.ps1 -generateVersion $true -autoCommitAndPush $true -autoGetLatestDevelop $true
Param
(
	[Parameter(Mandatory = $true)]
	[bool]$generateVersion,
	[Parameter(Mandatory = $true)]
	[bool]$autoCommitAndPush,
	[Parameter(Mandatory = $true)]
	[bool]$autoGetLatestDevelop
);

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
	
	return $commitItem.Substring(2, 7);
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
	
	return $commitItem.Substring(2, 40);
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
	{
		$userName = git config user.name;
		$userEmail = git config user.email;
		@("# v$version [$userName](mailto:$userEmail)") + (Get-Content $changeLogPath) | Set-Content $changeLogPath;
	}
	Else
	{
		$userCommit = git show -s --format='%an' $commitHash;
		$commitRecord = "* [$commitHash] ($userCommit) -> " + $commitComment;
		
		@($commitRecord) + (Get-Content $changeLogPath) | Set-Content $changeLogPath;
	}
}

#endregion

#region [Main Execution]

$brachToCheck = "develop";
$currentBranch = git branch --show-current;

If ($autoGetLatestDevelop -eq $true)
{
	Write-Host "#-------------------------------------------------------------------#" -ForegroundColor DarkGreen;
	Write-Host "#	Get the latest develop branch and commit to the current" -ForegroundColor Green;
	Write-Host "#-------------------------------------------------------------------#" -ForegroundColor DarkGreen;
	Write-Host "";
	
	# Auto get the latest 'develop' branch version and merge to the current branch
	git checkout $brachToCheck;
	git pull origin $brachToCheck;
	
	git checkout $currentBranch;
	git merge $brachToCheck;
}

# Generate commit changes
$brachDiffCommits = git cherry -v $brachToCheck $currentBranch;

If (($brachDiffCommits -ne $null -and ([Array]$brachDiffCommits).Length -gt 0) -or ($generateVersion -eq $true))
{
	# Add empty row before all commits
	Add-ChangeLog -changeType 0;
}

If ($brachDiffCommits -ne $null -and ([Array]$brachDiffCommits).Length -gt 0)
{
	Write-Host "#-------------------------------------------------------------------#" -ForegroundColor DarkGreen;
	Write-Host "#	Generate changelog (code comments) of the current branch" -ForegroundColor Green;
	Write-Host "#-------------------------------------------------------------------#" -ForegroundColor DarkGreen;
	Write-Host "";
	
	# Add new commit log
	foreach ($commitItem in $brachDiffCommits)
	{
		$commitHash = Get-CommitHash -commitItem $commitItem;
		$commitComment = Get-CommitMessage -commitItem $commitItem;
		
		Add-ChangeLog -changeType 2 -commitHash $commitHash -commitComment $commitComment;
	}
}

If ($generateVersion -eq $true)
{
	Write-Host "#-------------------------------------------------------------------#" -ForegroundColor DarkGreen;
	Write-Host "#	Generate new application version" -ForegroundColor Green;
	Write-Host "#-------------------------------------------------------------------#" -ForegroundColor DarkGreen;
	Write-Host "";
	
	# TODO: Find the best solution when to generate a new app version and append it to the changelog file
	# Generate new application version
	$appVersion = .\generate-new-version.ps1;
	Add-ChangeLog -changeType 1 -version $appVersion;
}

If ($autoCommitAndPush -eq $true) # Auto commit and push to origin
{
	Write-Host "#-------------------------------------------------------------------#" -ForegroundColor DarkGreen;
	Write-Host "#	Auto commit and push the current branch to the origin" -ForegroundColor Green;
	Write-Host "#-------------------------------------------------------------------#" -ForegroundColor DarkGreen;
	Write-Host "";
	
	$autoCommitMessage = "";
	If ($generateVersion -eq $true) { $autoCommitMessage = "Generate new application version and changelog from commits."; }
	Else { $autoCommitMessage = "Generate new application changelog from commits."; }
	
	git add --all;
	git commit -m $autoCommitMessage;
	git push -u origin $currentBranch;
}

#endregion
echo "Enter secure password for all users below"
$password = Read-Host -AsSecureString
Get-LocalUser > users.txt
Get-LocalGroupMember -Group "Administrators" > admins.txt
$users = @()
$admins = @()
$authorizedAdmins = @()
$authorizedUsers = @()

Get-Content users.txt | ForEach-Object {
	$users += ,$_.split(" ")[0]
}

Get-Content admins.txt | ForEach-Object {
    $admins += ,$_.split(" ")[8]
}

do {
	$input = (Read-Host "Please enter authorized admins one by one. Once finished, enter end")
	if ($input -ne '') {$authorizedAdmins += $input}
}
until ($input -eq 'end')

do {
	$inputs = (Read-Host "Please enter authorized users one by one. Once finished, enter end")
	if ($inputs -ne '') {$authorizedUsers += $inputs}
}
until ($inputs -eq 'end')

foreach ($user in $users) {
}

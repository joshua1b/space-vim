if (-not (Test-Path env:HOME)) {$env:HOME = ${env:USERPROFILE}}
if (-not (Test-Path env:APP_PATH)) {$env:APP_PATH= "${env:HOME}\.space-vim"}
$DOTSPACEVIM = "${env:HOME}\.space-vim"
$APP_NAME = "space-vim"
$REPO_URI = "https://github.com/liuchengxu/space-vim.git"
$REPO_BRANCH = "master"
$VIM_PLUG_PATH = "${env:HOME}\.vim\autoload"
$VIM_PLUG_URL = "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

function Msg
{
    Param(
        [string]$symbol=$null,
        [string]$str,
        [string]$color
    )
    if (-not $symbol)
    {
        Write-Host $symbol -ForegroundColor $color -NoNewline
    }
    Write-Host "$($str)"
}

function Success([string]$str) 
{
    if ($? -eq $true)
    {
        Msg -symbol "[✓]" -str $str -color "Green"
    }
}

function Error([string]$str)
{
    msg -symbol "[✗]" -str $str -color "Red"
    Write-Host "Press any key to exit ..."
    $x = $host.UI.RawUI.ReadKey("")
    exit
}

function Get-InstalledApps
{
    if ([IntPtr]::Size -eq 4) {
        $regpath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    }
    else {
        $regpath = @(
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
            'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )
    }
    Get-ItemProperty $regpath | .{process{if($_.DisplayName -and $_.UninstallString) { $_ } }} | Select DisplayName, Publisher, InstallDate, DisplayVersion, UninstallString |Sort DisplayName
}

function CheckExist ([string]$app_name)
{
    $result = Get-InstalledApps | where {$_.DisplayName -like $app_name}
    if ($result -eq $null) 
    {
        return ,$false    
    }
    return ,$true
}

function MustExist ([string]$app_name)
{
    $exist = $(CheckExist -app_name "$($app_name)*")
    if ($exist -eq $false)
    {
        Error -str "You must have '$($app_name)' installed to continue"
    }
}

function MklinkIf ([string]$target, [string]$source)
{
    if (Test-Path $source)
    {    
        cmd /c mklink $target $source   
    }
}

function Backup ([string]$backup)
{
    if (Test-Path $backup)
    {
        msg -str "Attempting to back up your original vim configuration."
        $today = Get-Date -UFormat "%Y%m%d_%s"
        Rename-Item -Path $backup -NewName "$($backup).$($today)"
        Success -str Your original vim configuration has been backed up.
    }
}

function MakeSymlink ([string]$target, [string]$source)
{
    MklinkIf -target "$($target)\.vimrc" -source "$($source)\init.vim"
    Success -str "Setting up vim symlinks."
}

function SyncRepo 
{
    Param 
    (
        [string]$repo_path,
        [string]$repo_uri,
        [string]$repo_branch,
        [string]$repo_name
    )
    if (-not (Test-Path $repo_path))
    {
        Write-Host "==>" -ForegroundColor "Blue" -NoNewline
        Write-Host "Trying to clone $($repo_name)"
        git clone -b $repo_branch $repo_uri $repo_path
        Success -str "Successfully cloned $($repo_name)."
    } 
    else 
    {
        Write-Host "==>" -ForegroundColor "Blue" -NoNewline
        Write-Host "Trying to update $($repo_name)"
        cd $repo_path
        git pull origin $repo_branch
        Success -str "Successfully updated $($repo_name)."
    }
}

function SyncVimplug ([string]$path, [string]$url)
{
    if (-not (Test-Path $path))
    {
        mkdir $path
        (New-Object System.Net.WebClient).DownloadFile($url, $path)
    }
}

function SetupVimplug
{
    vim -u "${env:HOME}\.vimrc" +PlugInstall! +PlugClean +qall
    Success -str "Now updating/installing plugins using vim-plug"
}

function MakeDotSpacevim
{
    if (-not (Test-Path $DOTSPACEVIM))
    {
        $text =@"
" You can enable the existing layers in space-vim and
" exclude the partial plugins in a certain layer.
" The command Layer and Exlcude are vaild in the function Layers().
function! Layers()
    " Default layers, recommended!
    Layer 'fzf'
    Layer 'unite'
    Layer 'better-defaults'
endfunction
" Put your private plugins here.
function! UserInit()
    " Space has been set as the default leader key,
    " if you want to change it, uncomment and set it here.
    " let g:spacevim_leader = "<\Space>"
    " let g:spacevim_localleader = ','
    " Install private plugins
    " Plug 'extr0py/oni'
endfunction
" Put your costom configurations here, e.g., change the colorscheme.
function! UserConfig()
    " If you enable airline layer and have installed the powerline fonts, set it here.
    " let g:airline_powerline_fonts=1
    " color desert
"@
        Set-Content -Path $DOTSPACEVIM -Value $text
    }
}

MustExist -app_name "Vim"
MustExist -app_name "Git"

Backup -backup "${env:HOME}\.virmc"

SyncRepo -repo_path $env:APP_PATH -repo_uri $REPO_URI -repo_branch $REPO_BRANCH -repo_name $APP_NAME

MakeSymlink -target $env:HOME -source $env:APP_PATH

SyncVimplug -path $VIM_PLUG_PATH -url $VIM_PLUG_URL

MakeDotSpacevim

SetupVimplug

Write-Host "Thanks for installing " -NoNewline
Msg -symbol $APP_NAME -str ". Enjoy!" -color "Red"

Write-Host "Press any key to exit ..."
$x = $host.UI.RawUI.ReadKey("")
exit
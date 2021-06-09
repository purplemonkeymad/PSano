# PSano

Text Editor a bit like nano, written in pure powershell.

## Features

Main feature that psano has over native editor is that it has access to
powershell objects, such as variables and functions. PSano supports
editing the following objects:

* Local files on the current computer.
* Remote files via a PSSession.
* Function definitions, changes will take effect in the current session.
* Variables, may be converted to a string array.

More or less anything that supports `Get/Set-Content` can work, but
the above have proper conversions.

## Usage

You can edit a file by just passing the path to psano, if you want to
create a new file just use the path you want to create.

    psano -Path .\test.txt

For remote files establish a session and pass it to psano.

    $RemoteSession = New-PSSession -ComputerName computer01
    psano -Path c:\full\path\test.txt -Session $RemoteSession

Separate parameters are used for variable and functions.

    psano -Variable myvar
    psano -Function New-Guid

## Hotkeys

Hotkeys are displayed at the bottom the of the window. Only basic actions
are implemented at this point in time.

* Control + X: Exit without saving.
* Control + O: Save file.
* Control + K: Cut current line and place it on the Clipboard.
* Control + U: Paste from the clipboard.

The Hotkeys mirror those used in nano for similar actions.

## Author

PurpleMonkeyMad  
https://github.com/purplemonkeymad  
/u/purplemonkeymad  

## About origin

I originally created it after if saw a post about editing files in a
PSSession without installing new files. I prototyped this but in the
end it was not going to work anyway for the problem. But since I had
the idea I finished a basic editor. It was not until later I realized
that the USP for this was going to be accessing PSDrives that were
not basic file systems.

This editor is not intended to be used for large editing jobs, just
the quick small changes that you might have messed something up and
you might need a character here or there.

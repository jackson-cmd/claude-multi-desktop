-- Claude Multi Desktop: a double-click front end for the claude-multi-desktop script bundled inside this app.
-- Unofficial; not affiliated with Anthropic. https://github.com/jackson-cmd/claude-multi-desktop
property appTitle : "Claude Multi Desktop"

on run
	set tool to "/bin/bash " & quoted form of POSIX path of (path to resource "claude-multi-desktop")
	set actions to {"Add an account", "Add a launcher for the account I already use", "Open an account", "Quit an account", "Quit every account (before updating Claude)", "Check and repair launchers", "Change a launcher's icon", "Rename a launcher", "Remove a launcher", "Show Claude Code sessions in every account"}
	repeat
		set picked to choose from list actions with title appTitle with prompt "Run several Claude Desktop accounts side by side. What would you like to do?" default items {"Add an account"} OK button name "Continue" cancel button name "Quit"
		if picked is false then exit repeat
		set action to item 1 of picked
		try
			if action is "Add an account" then
				my addAccount(tool, false)
			else if action is "Add a launcher for the account I already use" then
				my addAccount(tool, true)
			else if action is "Open an account" then
				set n to my pickLauncher(tool, "Open which account?")
				do shell script tool & " open " & quoted form of n
			else if action is "Quit an account" then
				set n to my pickLauncher(tool, "Quit Claude in which account?")
				set out to do shell script tool & " quit " & quoted form of n & " 2>&1 || true"
				display dialog out with title appTitle buttons {"OK"} default button "OK"
			else if action is "Quit every account (before updating Claude)" then
				set out to do shell script tool & " quit --all 2>&1 || true"
				display dialog out & return & return & "To update Claude, open it the normal way (or from your launcher for the account you already use) and choose Claude > Check for Updates. Then open your other accounts again." with title appTitle buttons {"OK"} default button "OK"
			else if action is "Check and repair launchers" then
				set out to do shell script tool & " doctor --fix 2>&1 || true"
				display dialog out with title appTitle buttons {"OK"} default button "OK"
			else if action is "Change a launcher's icon" then
				set n to my pickLauncher(tool, "Change the icon of which launcher?")
				set out to do shell script tool & " icon " & quoted form of n & my pickIcon(n)
				display dialog out with title appTitle buttons {"OK"} default button "OK"
			else if action is "Rename a launcher" then
				set n to my pickLauncher(tool, "Rename which launcher?")
				set newName to text returned of (display dialog "New name for Claude " & n & " (its sign-in and chats stay):" default answer n with title appTitle buttons {"Cancel", "Rename"} default button "Rename")
				set out to do shell script tool & " rename " & quoted form of n & " " & quoted form of newName
				display dialog out with title appTitle buttons {"OK"} default button "OK"
			else if action is "Remove a launcher" then
				set n to my pickLauncher(tool, "Remove which launcher?")
				display dialog "Remove the launcher Claude " & n & "? The account's sign-in and chats are kept, so adding it again later brings them back." with title appTitle buttons {"Cancel", "Remove"} default button "Cancel"
				set out to do shell script tool & " remove " & quoted form of n
				display dialog out with title appTitle buttons {"OK"} default button "OK"
			else
				set out to do shell script tool & " peers"
				display dialog out with title appTitle buttons {"OK"} default button "OK"
			end if
		on error msg number errNum
			if errNum is not -128 then display alert appTitle message msg as warning
		end try
	end repeat
end run

on addAccount(tool, isDefault)
	if isDefault then
		set question to "Name for the launcher that opens the account you already use:"
		set suggestion to "Main"
	else
		set question to "Name for the new account (letters, digits, spaces, - or _). The launcher will be called \"Claude <name>\"."
		set suggestion to "Work"
	end if
	set theName to text returned of (display dialog question default answer suggestion with title appTitle buttons {"Cancel", "Next"} default button "Next")
	set cmd to tool & " add " & quoted form of theName & my pickIcon(theName)
	if isDefault then set cmd to cmd & " --default"
	set out to do shell script cmd
	set reply to button returned of (display dialog out with title appTitle buttons {"Done", "Open it now"} default button "Open it now")
	if reply is "Open it now" then do shell script tool & " open " & quoted form of theName
end addAccount

on pickIcon(theName)
	set choice to button returned of (display dialog "Icon for Claude " & theName & ":" with title appTitle buttons {"A picture...", "Claude icon with a letter", "Coloured letter"} default button "Claude icon with a letter")
	if choice is "A picture..." then
		set f to choose file with prompt "Choose a picture for Claude " & theName of type {"public.image"}
		return " --icon " & quoted form of POSIX path of f
	end if
	if choice is "Claude icon with a letter" then
		set args to " --icon claude"
	else
		set args to " --icon letter"
	end if
	set c to button returned of (display dialog "Colour of the letter:" with title appTitle buttons {"Pick a colour...", "Automatic"} default button "Automatic")
	if c is "Pick a colour..." then set args to args & " --color " & my hexColor(choose color)
	return args
end pickIcon

on hexColor(rgb)
	set hexDigits to "0123456789ABCDEF"
	set out to ""
	repeat with v in rgb
		set n to (contents of v) div 257
		set out to out & (character ((n div 16) + 1) of hexDigits) & (character ((n mod 16) + 1) of hexDigits)
	end repeat
	return out
end hexColor

on pickLauncher(tool, promptText)
	set names to paragraphs of (do shell script tool & " list --names")
	if (count of names) is 0 or names is {""} then error "There are no launchers yet. Choose \"Add an account\" first."
	set picked to choose from list names with title appTitle with prompt promptText
	if picked is false then error number -128
	return item 1 of picked
end pickLauncher

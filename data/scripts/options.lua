gamelua.releaseBuild = true
gamelua.showEditor = true
gamelua.cheatsEnabled = true
gamelua.isPremium = false
gamelua.isKorea = false
gamelua.applyChinaRestictions = false
gamelua.gameVersionNumber = "1.6.3.1"--"1.6.3"
gamelua.g_registrationEnabled = not false
gamelua.g_updateCheckEnabled = true
gamelua.customer = ""
gamelua.customerString = "googleplay"
gamelua.svnRevisionNumber = "74023"
gamelua.isSeasonsAvailable = true
gamelua.isBetaVersion = false

gamelua.gameOptions = { --miscellaneous options
	slingshotCanceling = {enabled = true, downwards = false}, --0 = none, 1 = default, 2 = cancel while aiming downwards
	enableSweeping = true, --broken in default 1.6.3, but fine for every other version
	rotateWhileSlinging = false, --i implemented these 2 myself
	rotateWhileFlying = {enabled = false, allBirds = false}, --0 = none, 1 = rotate birds except hal and sardine can, 2 = rotate every bird (except sardine can)
	-- enableAngryBirds = true,

	mightyEagle = {
		enabled = true, --show eagle button
		showHighScore = true, --show eagle highscore
		showEagleScore = true, --show current eagle score
		showRegularScore = true --show normal score
	},
	
	enablePowerups = false,
	ui = {
		smoothScrolling = true,
		bigLevelSelection = false,
		menuLogo = "MENU_LOGO", --MENU_LOGO default, MENU_L2G0 for new version
		enableHoverScaling = true,
		enableCursor = true,
	},
	editor = {
		fixSelectionPage = true, --back buttons in the right position
		textPadding = 16 --padding of the top left text
	}
}

filename = "options.lua"
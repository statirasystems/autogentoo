Variable naming convention is in the following formats:

    Application:
        name
        
    Library:
        library_name
        
    Custom Execution Variables
            These can be set in the configuration file, from the global env, or any way you can assign a variable a value. They are defined here and in the STEPS.md file. Easiest is to put them in your config file or a custom file dropped into the config folder. The security checker will ignor these values. BE CAREFULL.
        _pre_stageOrfunction
        _post_stageOrfunction
        
        _pre_kernelconfig
        _post_baseinstall


Application Global
    dir - stores the location of the running script for finding and working with the supplimental library, config, and anything else required.
    envlanguage - stores the environment LANG setting. Used to retrieve the locale, unless the config says otherwise


Config Parameters

#This section is unorganized until first version complete

runtype="auto"
    This determines how the script is going to run. It basically has 3 ways it can run. The first is a headless mode where it just runs until complete or an error happens. The second and third are the same except config runs only to create the configuration and manual actually installs gentoo. They question the user the who way through.
    Options
        auto (default)
            from scratch and nothing is preconfigured
        auto3i
            from stage 3 installed but not portage
        auto3Pi
            from stage 3 with portage already installed
        config
            generates the configuration file
        manual
            installs while asking each step of the way

timezone="EST"
    Our script will only base time off of UTC and then overlay the timezone that the user specifies.
    Options
        the same as timezone on the system

mirrorregion="North America"
    set the region you are installing from. If none are selected it will scan through every mirror, so it is best to select a region if a speedy install is your desire.

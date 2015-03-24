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
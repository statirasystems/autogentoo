This is a list of features that are requested to be added or are on my roadmap (in my head lol). It is split into 2 primary sections. The first is what I am doing right now. The second is stuff I want to add or change.

Section 1

1. Split the large file into smaller more managable sizes. I will release an all in one file as well for easier downloading and running however, it will be generated and is not a priority until we get a functioning split one.
    Structure is as follows
        lib - this is the primary storage of the referenced functions of the script
        locale - this is where the localization files will be stored.
        kernel - this is where the kernel configurations will be stored
        config - this is where the configurations will be stored
        
        autogentoo - this is the primary script file for running.
        LICENSE - this is literally the license
        README.md - this is a general overview followed by the actual documentation. Except for the todo/roadmap as I am in the early stages.
        steps.md - the notes on the functions and what order they come in. It is modeled after Gentoo Handbook and easygentoo.
        todo.md - the todo/roadmap text document

Section 2

Since we will have two versions, manual and auto, there will be 3 sections, one for auto, one for manual, and another for both.

Both
- Determine the installing system. This will aid if a componant is missing. It can then go out and fetch it.
- Tester :: test if we can even run the scrpit on what they have. ie they put x86 disc and the profile asking to install x86_64
- Partitioning :: to add partitioning, we will have to add a way to detect what partinitioner they have. What schema type GPT or MBR. If they are making a mistake, ie Windows 8 is on their.
- try and incorporate more options of the file system, ie ntfs or apple's systems
- localization :: Split out the presentation of the script to be pulled from ${lang}-gui.localization. Default english us
- Model the install after the built in profiles. It inlcudes Portage profile is "${arch}/13.0/ for basic install" and "${arch}/13.0/desktop for normal install"
- incorporate wireless installer
- include a "ricer" mode.

- possibly include a stage 1/2 for complete customization (not a priority until others are done.)
- full config optimization. Including -j#, caching and any other.
- include every mirror and optimize based on region or just speed test all of them.
- use flag optimization based on selected packages
- kernel optimization

- include a way for user to store there own script commands in a variable or to attach their own scripts. Perhaps after each function run an exec varible with a name that identifies it with that step. Thus allowing for a user to incorporate functions they need to run on thier systems. ie echo $(post_functionname_scriptvariable) where the function

Manual
- config mode or runtime mode. Config mode is to generate a configuration file for other installs. Runtime executes the actul install


Auto/Headless
- output the install log file to the created user profile or root depending on what was selected in the configuration.

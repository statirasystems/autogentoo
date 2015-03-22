This is a list of features that are requested to be added or are on my roadmap (in my head lol).

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

Manual
- config mode or runtime mode. Config mode is to generate a configuration file for other installs. Runtime executes the actul install


Auto/Headless
- output the install log file to the created user profile or root depending on what was selected in the configuration.

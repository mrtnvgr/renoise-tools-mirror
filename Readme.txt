ABOUT MODFXRENDER
-----------------------------------------------------------
• Tool name: ModFXRender or MFR
• Version: 2.0 build 037
• Code Type: LUA 5.1 + API 6.1 (Renoise 3.4.3)
• Compatibility: Renoise v3.4.3 (tested under Windows 10/11)
• Publication Date: November 2023
• Development Time: March 2020 - November 2023
• Licence: GNU GPL. Prohibited use commercial ambit.
• Distribution: Full version
• Programmer: ulneiz (Spain)
• Contact Author: Go to https://forum.renoise.com/ & search "ulneiz" user (to contact you must be registered)
• Sponsor: Sick Puppy (Ireland) https://soundcloud.com/sick_puppy7


DESCRIPTION OF SAMRENDER:
-----------------------------------------------------------
ModFXRender is a massive sample rendering tool. It can take advantage of sample modulation sets, sample effect sets, phrases or track DSP effects to return rendered samples with these features. It also allows working with the initial and final silences of each sample, normalize and extend samples.

It also allows you to compress peaks across the board or compress an individual peak for re-editing. Very useful tasks for mastering and restoring audio waves after rendering. This tool can be supported with another tool called SamRender.


HOW TO INSTALL/UNISTALL THE MODFXRENDER?
-----------------------------------------------------------
• To install/update. The ModFXRender is an XRNX tool for Renoise. To install it, double-click on the file "name_of_tool.xrnx" or drag & drop the file on top of the Renoise window.
• To unistall. To unistall the ModFXRender, go to Renoise: Tools/Tool Browser..., search & select the tool & press the "Unistall" button.
• This tool is free distribution. No user registration required via license.


UPDATE HISTORY
-----------------------------------------------------------
ModFXRender v2.0.037 (November 2023)
• Modified: The entire "About ModFXRender" panel has been completely remodeled.
• Added: New oficial logo has been added.
• Improved: The "Silence" and "Normalize" subpanels now share the "Channel" option. Then, the "Clear Silence", "Insert Silence", "Normalize Sample", "Extend Sample" and "Compress Peaks" operations allow you to pre-select the L+R, L or R channels before operating.
 The operations "Normalize Sample", "Extend Sample" and "Compress Peaks" now allow working with very large audio waves, thanks to coroutines. They include a progress bar. Easily work with audio wave files longer than 10 minutes.
• Added: The operations "Normalize Sample", "Extend Sample" now have reduction value.
• Modified: The extend operation has been rebuilt.
• Modified: The subpanel "Silence Start/End Sound Wave" has been modified.
• Added: The "frames/min" value has been added to Sample Rate.
• Added: The "levels" value has been added to Bit Depth.
• Improved: When rendering with the "Accumulate" method, it will mute/unmute new samples to prevent new sound layers from interfering with the next samples to be rendered in the process.
• Fixed: Automatically deleting a temporary pattern (and track) after rendering can cause a aleatory crash (the pattern used should never be deleted during rendering).
• Improved: code revision.

• Improved: The value of "Threshold" to clear silence now has greater precision.
• Modified: New operator to "Surgical Compression Sound Wave (Mastering)".
• Modified: New subpanel for operator to "Surgical Change Peak (Mastering)".
• Added: The "frames/min" value has been added to Sample Rate.
• Added: The "levels" value has been added to Bit Depth.
• Improved: code revision.

ModFXRender v1.2.018 (May 2020)
• Added: new option: “Force transpose & finetune to 0”.
• Modified: show info panel.

ModFXRender v1.1.017 (March 2020)
• Added: new key commands & shortcuts.
• Added: list of keyboard commands.
• Added: more tooltips.
• Fixed: small fixes in the GUI.

ModFXRender v1.0.016 (March 2020)
• First release.

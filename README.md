#   ![icon](https://user-images.githubusercontent.com/1023003/68907111-347f9580-070c-11ea-8305-f81aa5abe73d.png) BambooCopy
BambooCopy is a tool written in Godot and C++ which can take your VOPM library and make it easy to preview and copy FM envelopes for import into [BambooTracker](https://github.com/rerrahkr/BambooTracker).  

Currently, to generate the audio preview an external tool, [FMGon](https://github.com/nobuyukinyuu/fmgon/) is used, and a binary is included.  To compile the preview generator requires linking against OpenAL and alut. A future version may incorporate the preview engine as an AudioStreamGenerator as part of Godot's audio system, removing this requirement.

BambooTracker uses OPNA style FM specifications, whereas VOPM uses OP-M.  The LFO differs between these two chips and is therefore not represented in the preview or the output.  LFO conversion may be implemented in the future, but will be OP-M->OPNA only.

# P1S maintenance log

## 2026-10-07: Z-axis squeak during downward motion

User reports squeaking when the Z axis descends, but not when it ascends.
Suspected cause: incorrect tension or tracking of the Z timing belt at the
bottom of the printer, possibly rubbing at the tensioner/idler. Record this
as a troubleshooting lead, not a confirmed diagnosis; no physical inspection
or adjustment has been performed.

Check the underside Z belt and tensioner against Bambu Lab's service guide:
https://wiki.bambulab.com/en/p1/maintenance/z-tensioner
The guide could not be retrieved by the automated browser during this run.
Do not confuse this belt with the XY belt tensioners at the rear.

The reinforced elastic-cord toy bow centre job (`bow-center_bed1.gcode`)
reported FAILED at layer 3 of 70, 0 percent, with print_error 0 when checked.
The printer was cold and not running. The status alone does not establish
why the print stopped or whether the squeak caused it.

User requested moving this job to the A1; no further P1S print was started.

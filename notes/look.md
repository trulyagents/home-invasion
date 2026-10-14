# look + sound

ui
- near black panels, thin dark red border, small corners
- cream text, grey for less important, blood red headings/timer
- Oswald bold headings, Gotham the rest
- most ui is in StarterGui (edit in studio). RoleClient + GameFeelClient make theirs in code
- bottom of screen from the bottom up: hotbar, weapon status, notices, role hints, then drag controls. don't put new stuff there

lighting: ~9pm, cool, a bit desaturated (DemoColorGrade, DemoAtmosphere)

sounds (SoundService.HomeInvasionPresentation)
- Heartbeat - protectors, invader within ~40 studs, louder closer (AtmosphereClient)
- PowerCut - lights out
- NightAmbience, InvasionCue, HitCue

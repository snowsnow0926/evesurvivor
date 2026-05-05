# Weapon Sound Effects

This directory contains weapon sound effects for the EVE-inspired weapons system.

## Required Sound Files

Place the following OGG files in this directory:

### Laser Weapons
- `laser_fire.ogg` - Laser weapon firing sound
  - Suggestion: A sustained energy hum/whine sound, similar to EVE's pulse laser effect
  - Duration: 0.3-0.5 seconds
  - Style: High-frequency electronic hum with energy build-up

### Railgun Weapons
- `railgun_fire.ogg` - Railgun firing sound
  - Suggestion: Heavy electrical discharge with metallic impact
  - Duration: 0.2-0.4 seconds
  - Style: Deep bass thump with electrical crackling, similar to EVE's railgun

### Cannon/Autocannon Weapons
- `cannon_fire.ogg` - Cannon firing sound
  - Suggestion: Heavy gun blast with metallic shell casing sounds
  - Duration: 0.2-0.3 seconds
  - Style: Deep explosive boom with mechanical feedback

### Missile Weapons
- `missile_launch.ogg` - Missile launch sound
  - Suggestion: Rocket/missile ignition with whoosh
  - Duration: 0.3-0.5 seconds
  - Style: Engine ignition followed by trailing whoosh

## Recommended Sources

You can create or source these sounds from:
1. **Freesound.org** - Creative Commons licensed sound effects
2. **ZapSplat.com** - Free sound effects (requires attribution)
3. **GameDev Market** - Affordable game audio packs
4. **Self-recorded** - Record your own using a microphone

## Technical Specifications

- Format: OGG Vorbis
- Sample Rate: 44100 Hz (CD quality)
- Bit Depth: 16-bit
- Channels: Mono or Stereo (mono preferred for efficiency)
- Volume: Normalized to -3dB to -6dB peak

## Notes

The game will still run without these files - the sounds will simply be silent.
SoundManager.play_sfx() will only play sounds if the file exists and is valid.

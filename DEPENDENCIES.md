# Forever dependency baseline

- FlareUI: [7.0.13](https://github.com/malkkav/FlareUI/releases/tag/7.0.13)
- Total RP 3: [3.5.5](https://github.com/Total-RP/Total-RP-3/releases/tag/3.5.5)
- Total RP 3: Extended (optional): [2.3.7](https://github.com/Total-RP/Total-RP-3-Extended/releases/tag/2.3.7)

Verification for the 7.0.13 adoption:

- Source: tagged `NP.UpdateColor` and `NP.BarColor` handle restricted cached colours. The adapter now requests the host repaint immediately and checks `barKnown` after the repaint.
- Automated: `./tools/check` passed, including profile refresh after a restricted bar colour and host fallback for a restricted colour or identity.
- In game: not verified.

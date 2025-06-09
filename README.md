# coin-sort

Run with:

`pico8 -run ./cart.p8`

Build with

`lua build.lua`

Test build with

`pico8 -run ./build.p8`

## Housekeeping

Regex to find violations of the standard for using '_' as a 'private' marker:

`(?<!function\s)\b(?!self\b)\w+:_`
